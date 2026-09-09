# MARC Conversion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `BibframeRuby.convert_marc` to convert MARC records to BIBFRAME Ruby objects via the LC marc2bibframe2 XSLT stylesheets.

**Architecture:** MarcConverter detects MARC format (binary vs XML), converts to MARCXML if needed, applies vendored XSLT to produce RDF/XML, then feeds into the existing Parser/GraphBuilder pipeline. The XSLT is vendored from lcnetdev/marc2bibframe2 v3.1.0.

**Tech Stack:** Ruby 3.2+, RSpec, `nokogiri` (XSLT), `marc` (binary MARC reading), `rdf-rdfxml` (RDF/XML parsing)

**Spec:** `docs/superpowers/specs/2026-09-09-marc-conversion-design.md`

## Global Constraints

- Ruby >= 3.2.0
- All files use `# frozen_string_literal: true`
- BIBFRAME namespace: `http://id.loc.gov/ontologies/bibframe/`
- Conventional commits
- TDD: write failing tests first, then implement
- marc2bibframe2 XSLT vendored at tag v3.1.0
- The XSLT requires `Dir.chdir` into the xsl directory (or equivalent) because it uses relative `xsl:include` paths
- Binary MARC detection: content starts with 5 digits (the MARC leader record length); MARCXML starts with `<`

---

### Task 1: Vendor XSLT, Add Dependencies, Add RDF/XML Parser Support

Vendor the marc2bibframe2 stylesheets, add `nokogiri` and `marc` to the gemspec, and add `:rdfxml` to Parser's READER_MAP.

**Files:**
- Create: `vendor/marc2bibframe2/xsl/` (copy from lcnetdev/marc2bibframe2 v3.1.0)
- Modify: `bibframe_ruby.gemspec` (add nokogiri, marc dependencies)
- Modify: `lib/bibframe_ruby/parser.rb` (add rdfxml reader)
- Create: `spec/bibframe_ruby/parser_rdfxml_spec.rb`
- Create: `spec/fixtures/work.rdf` (RDF/XML fixture for parser test)

**Interfaces:**
- Consumes: nothing new
- Produces: `Parser` supports `format: :rdfxml`, vendored XSL at `vendor/marc2bibframe2/xsl/marc2bibframe2.xsl`

- [ ] **Step 1: Clone and vendor the XSLT stylesheets**

```bash
cd /tmp && rm -rf marc2bibframe2
git clone --depth 1 --branch v3.1.0 https://github.com/lcnetdev/marc2bibframe2.git
mkdir -p vendor/marc2bibframe2
cp -r /tmp/marc2bibframe2/xsl vendor/marc2bibframe2/
```

Verify the vendored files are present:

```bash
ls vendor/marc2bibframe2/xsl/marc2bibframe2.xsl
ls vendor/marc2bibframe2/xsl/conf/codeMaps.xml
```

- [ ] **Step 2: Create an RDF/XML fixture**

Generate one by running the XSLT on a minimal MARCXML input:

```bash
bundle exec ruby -rnokogiri -e '
Dir.chdir("vendor/marc2bibframe2/xsl") do
  xsl = Nokogiri::XSLT(File.read("marc2bibframe2.xsl"))
  marcxml = %q(<?xml version="1.0" encoding="UTF-8"?>
  <collection xmlns="http://www.loc.gov/MARC21/slim">
    <record>
      <leader>00000nam a2200000 a 4500</leader>
      <controlfield tag="001">test123</controlfield>
      <controlfield tag="008">240101s2024    nyu           000 0 eng d</controlfield>
      <datafield tag="245" ind1="1" ind2="0">
        <subfield code="a">Test Title</subfield>
      </datafield>
    </record>
  </collection>)
  doc = Nokogiri::XML(marcxml)
  result = xsl.transform(doc, ["baseuri", "\"http://example.org/\"", "idsource", "\"test\""])
  File.write("../../../spec/fixtures/work.rdf", result.to_xml)
end
'
```

- [ ] **Step 3: Add dependencies to gemspec**

Add after the existing `rdf-turtle` dependency:

```ruby
spec.add_dependency "marc"
spec.add_dependency "nokogiri"
```

Run `bundle install` to update the lock file.

- [ ] **Step 4: Write failing RDF/XML parser spec**

```ruby
# spec/bibframe_ruby/parser_rdfxml_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby::Parser do
  let(:work_rdf) { read_fixture("work.rdf") }

  describe "RDF/XML parsing" do
    it "returns an RDF::Graph from RDF/XML input" do
      parser = described_class.new(work_rdf, format: :rdfxml)
      result = parser.parse
      expect(result).to be_a(RDF::Graph)
    end

    it "parses triples from RDF/XML input" do
      parser = described_class.new(work_rdf, format: :rdfxml)
      graph = parser.parse
      expect(graph.count).to be > 0
    end

    it "contains the work subject" do
      parser = described_class.new(work_rdf, format: :rdfxml)
      graph = parser.parse
      subjects = graph.subjects.map(&:to_s)
      expect(subjects).to include("http://example.org/test123#Work")
    end
  end
end

RSpec.describe BibframeRuby do
  describe "RDF/XML integration" do
    it "parses an RDF/XML file via parse_file" do
      result = described_class.parse_file(fixture_path("work.rdf"))
      expect(result).to be_a(BibframeRuby::Graph)
      expect(result.works.length).to eq(1)
    end

    it "produces a Work with a title from RDF/XML" do
      result = described_class.parse_file(fixture_path("work.rdf"))
      work = result.works.first
      expect(work.title).to be_a(BibframeRuby::Title)
      expect(work.title.main_title).to eq("Test Title")
    end
  end
end
```

- [ ] **Step 5: Run test to verify it fails**

Run: `bundle exec rspec spec/bibframe_ruby/parser_rdfxml_spec.rb`
Expected: FAIL with `Unsupported format: rdfxml`

- [ ] **Step 6: Add RDF/XML support to Parser**

In `lib/bibframe_ruby/parser.rb`, add the require and reader:

Add after `require "rdf/turtle"`:

```ruby
require "rdf/rdfxml"
```

Update READER_MAP:

```ruby
READER_MAP = {
  jsonld: JSON::LD::Reader,
  turtle: RDF::Turtle::Reader,
  rdfxml: RDF::RDFXML::Reader
}.freeze
```

- [ ] **Step 7: Run tests and verify they pass**

Run: `bundle exec rspec spec/bibframe_ruby/parser_rdfxml_spec.rb`
Expected: all pass

- [ ] **Step 8: Run full test suite**

Run: `bundle exec rspec`
Expected: all pass

- [ ] **Step 9: Commit**

```bash
git add vendor/marc2bibframe2/ spec/fixtures/work.rdf spec/bibframe_ruby/parser_rdfxml_spec.rb lib/bibframe_ruby/parser.rb bibframe_ruby.gemspec Gemfile.lock
git commit -m "feat: vendor marc2bibframe2 XSLT, add RDF/XML parser support, add nokogiri and marc dependencies"
```

---

### Task 2: MarcConverter

Create the MarcConverter class that converts MARC input to RDF/XML via XSLT.

**Files:**
- Create: `lib/bibframe_ruby/marc_converter.rb`
- Create: `spec/bibframe_ruby/marc_converter_spec.rb`
- Create: `spec/fixtures/record.mrc` (generated programmatically in spec setup)

**Interfaces:**
- Consumes: vendored XSLT at `vendor/marc2bibframe2/xsl/marc2bibframe2.xsl`, `nokogiri`, `marc` gems
- Produces: `BibframeRuby::MarcConverter.new(input, baseuri:, idsource:).convert` returns RDF/XML string

- [ ] **Step 1: Write failing MarcConverter spec**

```ruby
# spec/bibframe_ruby/marc_converter_spec.rb
# frozen_string_literal: true

require "marc"

RSpec.describe BibframeRuby::MarcConverter do
  let(:marcxml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <collection xmlns="http://www.loc.gov/MARC21/slim">
        <record>
          <leader>00000nam a2200000 a 4500</leader>
          <controlfield tag="001">conv123</controlfield>
          <controlfield tag="008">240101s2024    nyu           000 0 eng d</controlfield>
          <datafield tag="245" ind1="1" ind2="0">
            <subfield code="a">MARC Conversion Test</subfield>
          </datafield>
        </record>
      </collection>
    XML
  end

  let(:binary_marc) do
    record = MARC::Record.new
    record.leader = "00000nam a2200000 a 4500"
    record.append(MARC::ControlField.new("001", "conv456"))
    record.append(MARC::ControlField.new("008", "240101s2024    nyu           000 0 eng d"))
    record.append(MARC::DataField.new("245", "1", "0", ["a", "Binary MARC Test"]))
    writer = StringIO.new
    marc_writer = MARC::Writer.new(writer)
    marc_writer.write(record)
    marc_writer.close
    writer.string
  end

  describe "#convert" do
    it "converts MARCXML to RDF/XML" do
      converter = described_class.new(marcxml, baseuri: "http://example.org/", idsource: "test")
      result = converter.convert
      expect(result).to include("rdf:RDF")
      expect(result).to include("bf:Work")
      expect(result).to include("MARC Conversion Test")
    end

    it "converts binary MARC to RDF/XML" do
      converter = described_class.new(binary_marc, baseuri: "http://example.org/", idsource: "test")
      result = converter.convert
      expect(result).to include("rdf:RDF")
      expect(result).to include("bf:Work")
      expect(result).to include("Binary MARC Test")
    end

    it "passes baseuri to the XSLT" do
      converter = described_class.new(marcxml, baseuri: "http://mylib.org/catalog/", idsource: "test")
      result = converter.convert
      expect(result).to include("http://mylib.org/catalog/")
    end

    it "uses default baseuri when none provided" do
      converter = described_class.new(marcxml, idsource: "test")
      result = converter.convert
      expect(result).to include("http://example.org/")
    end
  end

  describe ".marcxml?" do
    it "returns true for XML content" do
      expect(described_class.marcxml?(marcxml)).to be true
    end

    it "returns false for binary MARC content" do
      expect(described_class.marcxml?(binary_marc)).to be false
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/bibframe_ruby/marc_converter_spec.rb`
Expected: FAIL with `uninitialized constant BibframeRuby::MarcConverter`

- [ ] **Step 3: Implement MarcConverter**

```ruby
# lib/bibframe_ruby/marc_converter.rb
# frozen_string_literal: true

# BibframeRuby::MarcConverter: Converts MARC records to BIBFRAME RDF/XML via XSLT

require "nokogiri"
require "marc"
require "stringio"

module BibframeRuby
  # Converts MARC (binary or MARCXML) to BIBFRAME RDF/XML using the vendored marc2bibframe2 XSLT.
  class MarcConverter
    XSL_DIR = File.expand_path("../../vendor/marc2bibframe2/xsl", __dir__)
    XSL_PATH = File.join(XSL_DIR, "marc2bibframe2.xsl")

    def initialize(input, baseuri: "http://example.org/", idsource: nil)
      @input = input
      @baseuri = baseuri
      @idsource = idsource
    end

    def convert
      xml = self.class.marcxml?(@input) ? @input : binary_to_marcxml(@input)
      doc = Nokogiri::XML(xml)
      rdfxml = transform(doc)
      rdfxml.to_xml
    end

    def self.marcxml?(input)
      input.lstrip.start_with?("<")
    end

    private

    def binary_to_marcxml(input)
      reader = MARC::Reader.new(StringIO.new(input))
      output = StringIO.new
      writer = MARC::XMLWriter.new(output)
      reader.each { |record| writer.write(record) }
      writer.close
      output.string
    end

    def transform(doc)
      params = ["baseuri", "\"#{@baseuri}\""]
      params += ["idsource", "\"#{@idsource}\""] if @idsource

      Dir.chdir(XSL_DIR) do
        self.class.stylesheet.transform(doc, params)
      end
    end

    def self.stylesheet
      @stylesheet ||= Dir.chdir(XSL_DIR) do
        Nokogiri::XSLT(File.read(XSL_PATH))
      end
    end
  end
end
```

- [ ] **Step 4: Add require to bibframe_ruby.rb**

Add after `require_relative "bibframe_ruby/graph"`:

```ruby
require_relative "bibframe_ruby/marc_converter"
```

- [ ] **Step 5: Run tests and verify they pass**

Run: `bundle exec rspec spec/bibframe_ruby/marc_converter_spec.rb`
Expected: all pass

- [ ] **Step 6: Commit**

```bash
git add lib/bibframe_ruby/marc_converter.rb spec/bibframe_ruby/marc_converter_spec.rb lib/bibframe_ruby.rb
git commit -m "feat: add MarcConverter for MARC to RDF/XML conversion via XSLT"
```

---

### Task 3: Public API and Integration Tests

Add `BibframeRuby.convert_marc` and integration tests that verify the full pipeline.

**Files:**
- Modify: `lib/bibframe_ruby.rb` (add `self.convert_marc`)
- Create: `spec/convert_marc_spec.rb`

**Interfaces:**
- Consumes: `BibframeRuby::MarcConverter.new(input, baseuri:, idsource:).convert` returns RDF/XML string, `BibframeRuby.parse(input, format: :rdfxml)` returns Graph
- Produces: `BibframeRuby.convert_marc(path, baseuri:, idsource:)` returns `BibframeRuby::Graph`

- [ ] **Step 1: Create a binary MARC fixture file**

```ruby
# Run this to create the fixture:
bundle exec ruby -e '
require "marc"
record = MARC::Record.new
record.leader = "00000nam a2200000 a 4500"
record.append(MARC::ControlField.new("001", "fixture789"))
record.append(MARC::ControlField.new("008", "240101s2024    nyu           000 0 eng d"))
record.append(MARC::DataField.new("245", "1", "0", ["a", "Fixture MARC Record"]))
record.append(MARC::DataField.new("260", " ", " ", ["a", "New York :"], ["b", "Publisher,"], ["c", "2024."]))
writer = MARC::Writer.new("spec/fixtures/record.mrc")
writer.write(record)
writer.close
'
```

- [ ] **Step 2: Write failing integration spec**

```ruby
# spec/convert_marc_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby do
  describe ".convert_marc" do
    let(:marc_path) { fixture_path("record.mrc") }

    it "returns a Graph" do
      result = described_class.convert_marc(marc_path)
      expect(result).to be_a(BibframeRuby::Graph)
    end

    it "produces Works from MARC" do
      result = described_class.convert_marc(marc_path)
      expect(result.works.length).to eq(1)
    end

    it "produces Instances from MARC" do
      result = described_class.convert_marc(marc_path)
      expect(result.instances.length).to eq(1)
    end

    it "populates the Work title" do
      result = described_class.convert_marc(marc_path)
      work = result.works.first
      expect(work.title).to be_a(BibframeRuby::Title)
      expect(work.title.main_title).to eq("Fixture MARC Record")
    end

    it "passes baseuri through to the transform" do
      result = described_class.convert_marc(marc_path, baseuri: "http://mylib.org/")
      work = result.works.first
      expect(work.id).to start_with("http://mylib.org/")
    end

    it "populates the Work language" do
      result = described_class.convert_marc(marc_path)
      work = result.works.first
      expect(work.language).to eq("http://id.loc.gov/vocabulary/languages/eng")
    end
  end
end
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bundle exec rspec spec/convert_marc_spec.rb`
Expected: FAIL with `NoMethodError: undefined method 'convert_marc'`

- [ ] **Step 4: Implement convert_marc**

Add to `lib/bibframe_ruby.rb`, after the `parse_uri` method:

```ruby
def self.convert_marc(path, baseuri: "http://example.org/", idsource: nil)
  input = File.read(path)
  rdfxml = MarcConverter.new(input, baseuri: baseuri, idsource: idsource).convert
  parse(rdfxml, format: :rdfxml)
end
```

- [ ] **Step 5: Run tests and verify they pass**

Run: `bundle exec rspec spec/convert_marc_spec.rb`
Expected: all pass

- [ ] **Step 6: Run full test suite**

Run: `bundle exec rspec`
Expected: all pass

- [ ] **Step 7: Commit**

```bash
git add lib/bibframe_ruby.rb spec/convert_marc_spec.rb spec/fixtures/record.mrc
git commit -m "feat: add convert_marc public API for MARC to BIBFRAME conversion"
```

---

### Task 4: Update README

Add MARC conversion documentation to the README.

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: everything from Tasks 1-3
- Produces: updated documentation

- [ ] **Step 1: Read the current README**

Read `README.md` to understand the existing structure.

- [ ] **Step 2: Add MARC conversion section**

After the "Combining Multiple Documents" section and before "Stub Resources", add:

```markdown
### Converting from MARC

Convert MARC records (binary MARC21 or MARCXML) to BIBFRAME using the Library of Congress [marc2bibframe2](https://github.com/lcnetdev/marc2bibframe2) XSLT stylesheets:

```ruby
# Convert a binary MARC file
graph = BibframeRuby.convert_marc("record.mrc")

# With a custom base URI for minted resource URIs
graph = BibframeRuby.convert_marc("record.mrc", baseuri: "https://mylib.org/catalog/")

# MARCXML is also accepted
graph = BibframeRuby.convert_marc("record.xml", baseuri: "https://mylib.org/catalog/")

graph.works.first.title.main_title
# => "The Title"
```

The `baseuri` parameter controls the base URI for generated resource identifiers (default: `http://example.org/`). The optional `idsource` parameter identifies the converting agent.
```

Also add to the Supported Formats table:

```
| MARC21 (binary) | Supported (convert) | `.mrc` |
| MARCXML | Supported (convert) | `.xml` |
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add MARC conversion to README"
```
