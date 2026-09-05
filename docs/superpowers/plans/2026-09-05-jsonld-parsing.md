# JSON-LD Parsing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Parse BIBFRAME JSON-LD documents into Ruby objects with idiomatic accessors and linked relationships.

**Architecture:** RDF gem stack parses JSON-LD into triples. A GraphBuilder walks triples to hydrate typed model objects (Work, Instance, Item, etc.) and links their relationships. A Graph container provides collection accessors.

**Tech Stack:** Ruby 3.2+, RSpec, `json-ld` gem, `rdf` gem

**Spec:** `docs/superpowers/specs/2026-09-05-jsonld-parsing-design.md`

## Global Constraints

- Ruby >= 3.2.0
- All files use `# frozen_string_literal: true`
- BIBFRAME namespace: `http://id.loc.gov/ontologies/bibframe/`
- BFLC namespace: `http://id.loc.gov/ontologies/bflc/`
- Conventional commits with issue reference
- TDD: write failing tests first, then implement

---

### Task 1: Fixtures and Resource Base Class

Set up test fixtures and the `Resource` base class that all models inherit from.

**Files:**
- Create: `spec/fixtures/work.jsonld`
- Create: `spec/fixtures/instance.jsonld`
- Create: `lib/bibframe_ruby/resource.rb`
- Create: `spec/models/resource_spec.rb`
- Modify: `lib/bibframe_ruby.rb`

**Interfaces:**
- Consumes: nothing
- Produces: `BibframeRuby::Resource.new(id:, types:, properties:)`, `#id`, `#types`, `#properties`, `#[]`, `#[]=`

- [ ] **Step 1: Download fixtures**

Save the sample JSON-LD documents as test fixtures:

```bash
curl -s 'https://dev.bcld.info/works/25305194-1115-43ab-8a7c-4ef586a1e8e5.jsonld' | ruby -rjson -e 'puts JSON.pretty_generate(JSON.parse(STDIN.read))' > spec/fixtures/work.jsonld
curl -s 'https://dev.bcld.info/instances/4e0a7e08-b92a-46e5-8827-bdb635fef24a.jsonld' | ruby -rjson -e 'puts JSON.pretty_generate(JSON.parse(STDIN.read))' > spec/fixtures/instance.jsonld
```

- [ ] **Step 2: Write failing Resource spec**

```ruby
# spec/models/resource_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby::Resource do
  subject(:resource) do
    described_class.new(
      id: "http://example.org/works/1",
      types: ["Work", "Text"],
      properties: { "title" => "Test Title" }
    )
  end

  describe "#id" do
    it "returns the URI" do
      expect(resource.id).to eq("http://example.org/works/1")
    end
  end

  describe "#types" do
    it "returns the type array" do
      expect(resource.types).to eq(["Work", "Text"])
    end
  end

  describe "#properties" do
    it "returns the properties hash" do
      expect(resource.properties).to eq({ "title" => "Test Title" })
    end
  end

  describe "#[]" do
    it "accesses properties by string key" do
      expect(resource["title"]).to eq("Test Title")
    end

    it "accesses properties by symbol key" do
      expect(resource[:title]).to eq("Test Title")
    end

    it "returns nil for missing keys" do
      expect(resource["missing"]).to be_nil
    end
  end

  describe "#[]=" do
    it "sets properties" do
      resource["language"] = "eng"
      expect(resource["language"]).to eq("eng")
    end
  end
end
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bundle exec rspec spec/models/resource_spec.rb`
Expected: FAIL with `uninitialized constant BibframeRuby::Resource`

- [ ] **Step 4: Implement Resource**

```ruby
# lib/bibframe_ruby/resource.rb
# frozen_string_literal: true

module BibframeRuby
  class Resource
    attr_reader :id, :types
    attr_accessor :properties

    def initialize(id: nil, types: [], properties: {})
      @id = id
      @types = types
      @properties = properties
    end

    def [](key)
      @properties[key.to_s]
    end

    def []=(key, value)
      @properties[key.to_s] = value
    end
  end
end
```

- [ ] **Step 5: Update bibframe_ruby.rb to require resource**

Add to `lib/bibframe_ruby.rb`:

```ruby
require_relative "bibframe_ruby/resource"
```

- [ ] **Step 6: Run tests and verify they pass**

Run: `bundle exec rspec spec/models/resource_spec.rb`
Expected: all pass

- [ ] **Step 7: Commit**

```bash
git add spec/fixtures/ spec/models/resource_spec.rb lib/bibframe_ruby/resource.rb lib/bibframe_ruby.rb
git commit -m "feat: add Resource base class and test fixtures"
```

---

### Task 2: Model Classes

Create all model subclasses with their named accessors.

**Files:**
- Create: `lib/bibframe_ruby/models/work.rb`
- Create: `lib/bibframe_ruby/models/instance.rb`
- Create: `lib/bibframe_ruby/models/item.rb`
- Create: `lib/bibframe_ruby/models/contribution.rb`
- Create: `lib/bibframe_ruby/models/agent.rb`
- Create: `lib/bibframe_ruby/models/person.rb`
- Create: `lib/bibframe_ruby/models/organization.rb`
- Create: `lib/bibframe_ruby/models/title.rb`
- Create: `lib/bibframe_ruby/models/subject.rb`
- Create: `spec/models/work_spec.rb`
- Create: `spec/models/instance_spec.rb`
- Create: `spec/models/item_spec.rb`
- Create: `spec/models/contribution_spec.rb`
- Create: `spec/models/title_spec.rb`
- Create: `spec/models/agent_spec.rb`
- Create: `spec/models/subject_spec.rb`
- Modify: `lib/bibframe_ruby.rb`

**Interfaces:**
- Consumes: `BibframeRuby::Resource` (base class)
- Produces: `BibframeRuby::Work` (`#title`, `#contributions`, `#instances`, `#language`, `#subjects`, `#genre_forms`, `#summary`, `#classifications`, `#relations`), `BibframeRuby::Instance` (`#title`, `#work`, `#identifiers`, `#extent`, `#carrier`, `#media`, `#provision_activity`, `#edition_statement`, `#dimensions`, `#publication_statement`, `#items`), `BibframeRuby::Item` (`#instance`, `#held_by`, `#shelf_mark`), `BibframeRuby::Contribution` (`#agent`, `#role`, `#primary?`), `BibframeRuby::Title` (`#main_title`, `#subtitle`, `#non_sort_num`), `BibframeRuby::Agent` / `Person` / `Organization` (`#label`), `BibframeRuby::Subject` (`#label`, `#source`)

- [ ] **Step 1: Write failing model specs**

```ruby
# spec/models/title_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby::Title do
  subject(:title) do
    described_class.new(
      properties: {
        "main_title" => "The dungeon anarchist's cookbook",
        "subtitle" => "A novel",
        "non_sort_num" => "4"
      }
    )
  end

  it "inherits from Resource" do
    expect(title).to be_a(BibframeRuby::Resource)
  end

  describe "#main_title" do
    it "returns the main title" do
      expect(title.main_title).to eq("The dungeon anarchist's cookbook")
    end
  end

  describe "#subtitle" do
    it "returns the subtitle" do
      expect(title.subtitle).to eq("A novel")
    end
  end

  describe "#non_sort_num" do
    it "returns the non-sort number" do
      expect(title.non_sort_num).to eq("4")
    end
  end
end
```

```ruby
# spec/models/work_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby::Work do
  subject(:work) do
    described_class.new(
      id: "http://example.org/works/1",
      types: ["Work", "Text"],
      properties: {
        "title" => title,
        "language" => "http://id.loc.gov/vocabulary/languages/eng",
        "summary" => "A test summary",
        "contributions" => [contribution],
        "genre_forms" => ["http://id.loc.gov/authorities/genreForms/gf2014026339"],
        "classifications" => [],
        "relations" => []
      }
    )
  end

  let(:title) { BibframeRuby::Title.new(properties: { "main_title" => "Test Work" }) }
  let(:contribution) { BibframeRuby::Contribution.new(properties: { "role" => "aut", "primary" => true }) }

  it "inherits from Resource" do
    expect(work).to be_a(BibframeRuby::Resource)
  end

  describe "#title" do
    it "returns the Title object" do
      expect(work.title).to eq(title)
    end
  end

  describe "#contributions" do
    it "returns the contributions array" do
      expect(work.contributions).to eq([contribution])
    end
  end

  describe "#instances" do
    it "defaults to empty array" do
      expect(work.instances).to eq([])
    end
  end

  describe "#language" do
    it "returns the language" do
      expect(work.language).to eq("http://id.loc.gov/vocabulary/languages/eng")
    end
  end

  describe "#summary" do
    it "returns the summary" do
      expect(work.summary).to eq("A test summary")
    end
  end

  describe "#genre_forms" do
    it "returns the genre forms array" do
      expect(work.genre_forms).to eq(["http://id.loc.gov/authorities/genreForms/gf2014026339"])
    end
  end

  describe "#subjects" do
    it "defaults to empty array" do
      expect(work.subjects).to eq([])
    end
  end
end
```

```ruby
# spec/models/instance_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby::Instance do
  subject(:instance) do
    described_class.new(
      id: "http://example.org/instances/1",
      types: ["Instance"],
      properties: {
        "title" => title,
        "extent" => "532 pages",
        "dimensions" => "24 cm",
        "edition_statement" => "First Ace edition",
        "publication_statement" => "New York: Ace, 2024",
        "identifiers" => [],
        "carrier" => "http://id.loc.gov/vocabulary/carriers/nc",
        "media" => "http://id.loc.gov/vocabulary/mediaTypes/n"
      }
    )
  end

  let(:title) { BibframeRuby::Title.new(properties: { "main_title" => "Test" }) }

  it "inherits from Resource" do
    expect(instance).to be_a(BibframeRuby::Resource)
  end

  describe "#title" do
    it "returns the Title" do
      expect(instance.title).to eq(title)
    end
  end

  describe "#work" do
    it "defaults to nil" do
      expect(instance.work).to be_nil
    end
  end

  describe "#extent" do
    it "returns the extent" do
      expect(instance.extent).to eq("532 pages")
    end
  end

  describe "#dimensions" do
    it "returns the dimensions" do
      expect(instance.dimensions).to eq("24 cm")
    end
  end

  describe "#edition_statement" do
    it "returns the edition statement" do
      expect(instance.edition_statement).to eq("First Ace edition")
    end
  end

  describe "#publication_statement" do
    it "returns the publication statement" do
      expect(instance.publication_statement).to eq("New York: Ace, 2024")
    end
  end

  describe "#items" do
    it "defaults to empty array" do
      expect(instance.items).to eq([])
    end
  end

  describe "#identifiers" do
    it "returns the identifiers array" do
      expect(instance.identifiers).to eq([])
    end
  end
end
```

```ruby
# spec/models/item_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby::Item do
  subject(:item) do
    described_class.new(
      id: "http://example.org/items/1",
      types: ["Item"],
      properties: {
        "held_by" => "http://example.org/org/1",
        "shelf_mark" => "PS3604.I49 D85 2024"
      }
    )
  end

  it "inherits from Resource" do
    expect(item).to be_a(BibframeRuby::Resource)
  end

  describe "#instance" do
    it "defaults to nil" do
      expect(item.instance).to be_nil
    end
  end

  describe "#held_by" do
    it "returns the holding organization" do
      expect(item.held_by).to eq("http://example.org/org/1")
    end
  end

  describe "#shelf_mark" do
    it "returns the shelf mark" do
      expect(item.shelf_mark).to eq("PS3604.I49 D85 2024")
    end
  end
end
```

```ruby
# spec/models/contribution_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby::Contribution do
  subject(:contribution) do
    described_class.new(
      properties: {
        "agent" => agent,
        "role" => "http://id.loc.gov/vocabulary/relators/aut",
        "primary" => true
      }
    )
  end

  let(:agent) { BibframeRuby::Resource.new(id: "http://id.loc.gov/rwo/agents/no2023085548") }

  it "inherits from Resource" do
    expect(contribution).to be_a(BibframeRuby::Resource)
  end

  describe "#agent" do
    it "returns the agent" do
      expect(contribution.agent).to eq(agent)
    end
  end

  describe "#role" do
    it "returns the role URI" do
      expect(contribution.role).to eq("http://id.loc.gov/vocabulary/relators/aut")
    end
  end

  describe "#primary?" do
    it "returns true for primary contributions" do
      expect(contribution.primary?).to be true
    end

    it "returns false when not primary" do
      non_primary = described_class.new(properties: { "primary" => false })
      expect(non_primary.primary?).to be false
    end
  end
end
```

```ruby
# spec/models/agent_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby::Agent do
  subject(:agent) do
    described_class.new(
      id: "http://id.loc.gov/rwo/agents/no2023085548",
      properties: { "label" => "Dinniman, Matt" }
    )
  end

  it "inherits from Resource" do
    expect(agent).to be_a(BibframeRuby::Resource)
  end

  describe "#label" do
    it "returns the label" do
      expect(agent.label).to eq("Dinniman, Matt")
    end
  end
end

RSpec.describe BibframeRuby::Person do
  it "inherits from Agent" do
    expect(described_class.new).to be_a(BibframeRuby::Agent)
  end
end

RSpec.describe BibframeRuby::Organization do
  it "inherits from Agent" do
    expect(described_class.new).to be_a(BibframeRuby::Agent)
  end
end
```

```ruby
# spec/models/subject_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby::Subject do
  subject(:subj) do
    described_class.new(
      properties: {
        "label" => "Fantasy fiction",
        "source" => "http://id.loc.gov/authorities/subjects"
      }
    )
  end

  it "inherits from Resource" do
    expect(subj).to be_a(BibframeRuby::Resource)
  end

  describe "#label" do
    it "returns the label" do
      expect(subj.label).to eq("Fantasy fiction")
    end
  end

  describe "#source" do
    it "returns the source" do
      expect(subj.source).to eq("http://id.loc.gov/authorities/subjects")
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/models/`
Expected: FAIL with `uninitialized constant` errors

- [ ] **Step 3: Implement all model classes**

```ruby
# lib/bibframe_ruby/models/title.rb
# frozen_string_literal: true

module BibframeRuby
  class Title < Resource
    def main_title
      self["main_title"]
    end

    def subtitle
      self["subtitle"]
    end

    def non_sort_num
      self["non_sort_num"]
    end
  end
end
```

```ruby
# lib/bibframe_ruby/models/work.rb
# frozen_string_literal: true

module BibframeRuby
  class Work < Resource
    def title
      self["title"]
    end

    def contributions
      self["contributions"] || []
    end

    def instances
      self["instances"] || []
    end

    def language
      self["language"]
    end

    def subjects
      self["subjects"] || []
    end

    def genre_forms
      self["genre_forms"] || []
    end

    def summary
      self["summary"]
    end

    def classifications
      self["classifications"] || []
    end

    def relations
      self["relations"] || []
    end
  end
end
```

```ruby
# lib/bibframe_ruby/models/instance.rb
# frozen_string_literal: true

module BibframeRuby
  class Instance < Resource
    def title
      self["title"]
    end

    def work
      self["work"]
    end

    def identifiers
      self["identifiers"] || []
    end

    def extent
      self["extent"]
    end

    def carrier
      self["carrier"]
    end

    def media
      self["media"]
    end

    def provision_activity
      self["provision_activity"]
    end

    def edition_statement
      self["edition_statement"]
    end

    def dimensions
      self["dimensions"]
    end

    def publication_statement
      self["publication_statement"]
    end

    def items
      self["items"] || []
    end
  end
end
```

```ruby
# lib/bibframe_ruby/models/item.rb
# frozen_string_literal: true

module BibframeRuby
  class Item < Resource
    def instance
      self["instance"]
    end

    def held_by
      self["held_by"]
    end

    def shelf_mark
      self["shelf_mark"]
    end
  end
end
```

```ruby
# lib/bibframe_ruby/models/contribution.rb
# frozen_string_literal: true

module BibframeRuby
  class Contribution < Resource
    def agent
      self["agent"]
    end

    def role
      self["role"]
    end

    def primary?
      self["primary"] == true
    end
  end
end
```

```ruby
# lib/bibframe_ruby/models/agent.rb
# frozen_string_literal: true

module BibframeRuby
  class Agent < Resource
    def label
      self["label"]
    end
  end
end
```

```ruby
# lib/bibframe_ruby/models/person.rb
# frozen_string_literal: true

module BibframeRuby
  class Person < Agent
  end
end
```

```ruby
# lib/bibframe_ruby/models/organization.rb
# frozen_string_literal: true

module BibframeRuby
  class Organization < Agent
  end
end
```

```ruby
# lib/bibframe_ruby/models/subject.rb
# frozen_string_literal: true

module BibframeRuby
  class Subject < Resource
    def label
      self["label"]
    end

    def source
      self["source"]
    end
  end
end
```

- [ ] **Step 4: Update bibframe_ruby.rb to require all models**

Add to `lib/bibframe_ruby.rb`:

```ruby
require_relative "bibframe_ruby/models/title"
require_relative "bibframe_ruby/models/work"
require_relative "bibframe_ruby/models/instance"
require_relative "bibframe_ruby/models/item"
require_relative "bibframe_ruby/models/contribution"
require_relative "bibframe_ruby/models/agent"
require_relative "bibframe_ruby/models/person"
require_relative "bibframe_ruby/models/organization"
require_relative "bibframe_ruby/models/subject"
```

- [ ] **Step 5: Run tests and verify they pass**

Run: `bundle exec rspec spec/models/`
Expected: all pass

- [ ] **Step 6: Commit**

```bash
git add lib/bibframe_ruby/models/ lib/bibframe_ruby.rb spec/models/
git commit -m "feat: add model classes with named accessors"
```

---

### Task 3: Parser

Parse JSON-LD strings into RDF graphs with format detection.

**Files:**
- Create: `lib/bibframe_ruby/parser.rb`
- Create: `spec/parser_spec.rb`
- Modify: `lib/bibframe_ruby.rb`

**Interfaces:**
- Consumes: nothing (uses `json-ld` and `rdf` gems directly)
- Produces: `BibframeRuby::Parser.new(input, format:).parse` returns `RDF::Graph`; `BibframeRuby::Parser.format_for_extension(ext)` returns format symbol

- [ ] **Step 1: Write failing Parser spec**

```ruby
# spec/parser_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby::Parser do
  let(:work_jsonld) { File.read(File.join(__dir__, "fixtures/work.jsonld")) }

  describe "#parse" do
    it "returns an RDF::Graph" do
      parser = described_class.new(work_jsonld, format: :jsonld)
      result = parser.parse
      expect(result).to be_a(RDF::Graph)
    end

    it "parses triples from JSON-LD input" do
      parser = described_class.new(work_jsonld, format: :jsonld)
      graph = parser.parse
      expect(graph.count).to be > 0
    end

    it "contains the work subject" do
      parser = described_class.new(work_jsonld, format: :jsonld)
      graph = parser.parse
      subjects = graph.subjects.map(&:to_s)
      expect(subjects).to include("https://dev.bcld.info/works/25305194-1115-43ab-8a7c-4ef586a1e8e5")
    end
  end

  describe ".format_for_extension" do
    it "returns :jsonld for .jsonld" do
      expect(described_class.format_for_extension(".jsonld")).to eq(:jsonld)
    end

    it "returns :turtle for .ttl" do
      expect(described_class.format_for_extension(".ttl")).to eq(:turtle)
    end

    it "returns :rdfxml for .rdf" do
      expect(described_class.format_for_extension(".rdf")).to eq(:rdfxml)
    end

    it "raises for unknown extensions" do
      expect { described_class.format_for_extension(".xyz") }.to raise_error(BibframeRuby::Error)
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/parser_spec.rb`
Expected: FAIL with `uninitialized constant BibframeRuby::Parser`

- [ ] **Step 3: Implement Parser**

```ruby
# lib/bibframe_ruby/parser.rb
# frozen_string_literal: true

require "rdf"
require "json/ld"

module BibframeRuby
  class Parser
    EXTENSION_MAP = {
      ".jsonld" => :jsonld,
      ".ttl" => :turtle,
      ".rdf" => :rdfxml
    }.freeze

    READER_MAP = {
      jsonld: JSON::LD::Reader
    }.freeze

    def initialize(input, format: :jsonld)
      @input = input
      @format = format
    end

    def parse
      reader_class = READER_MAP.fetch(@format) do
        raise BibframeRuby::Error, "Unsupported format: #{@format}"
      end

      graph = RDF::Graph.new
      reader_class.new(@input) { |reader| graph << reader }
      graph
    end

    def self.format_for_extension(ext)
      EXTENSION_MAP.fetch(ext) do
        raise BibframeRuby::Error, "Unknown file extension: #{ext}"
      end
    end
  end
end
```

- [ ] **Step 4: Update bibframe_ruby.rb to require parser**

Add to `lib/bibframe_ruby.rb`:

```ruby
require_relative "bibframe_ruby/parser"
```

- [ ] **Step 5: Run tests and verify they pass**

Run: `bundle exec rspec spec/parser_spec.rb`
Expected: all pass

- [ ] **Step 6: Commit**

```bash
git add lib/bibframe_ruby/parser.rb spec/parser_spec.rb lib/bibframe_ruby.rb
git commit -m "feat: add Parser for JSON-LD to RDF graph conversion"
```

---

### Task 4: GraphBuilder

Walk the RDF graph, instantiate typed model objects, and link relationships.

**Files:**
- Create: `lib/bibframe_ruby/graph_builder.rb`
- Create: `spec/graph_builder_spec.rb`
- Modify: `lib/bibframe_ruby.rb`

**Interfaces:**
- Consumes: `BibframeRuby::Parser#parse` (returns `RDF::Graph`), all model classes
- Produces: `BibframeRuby::GraphBuilder.new(rdf_graph).build` returns `{ resources: Hash<String, Resource>, works: [Work], instances: [Instance], items: [Item] }`

- [ ] **Step 1: Write failing GraphBuilder spec**

```ruby
# spec/graph_builder_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby::GraphBuilder do
  let(:work_jsonld) { File.read(File.join(__dir__, "fixtures/work.jsonld")) }
  let(:rdf_graph) { BibframeRuby::Parser.new(work_jsonld, format: :jsonld).parse }
  let(:result) { described_class.new(rdf_graph).build }

  describe "#build" do
    it "returns a hash with resources" do
      expect(result).to have_key(:resources)
      expect(result[:resources]).to be_a(Hash)
    end

    it "returns a hash with works array" do
      expect(result[:works]).to be_an(Array)
      expect(result[:works].length).to eq(1)
    end

    it "creates a Work instance for bf:Work typed resources" do
      work = result[:works].first
      expect(work).to be_a(BibframeRuby::Work)
    end

    it "sets the work id" do
      work = result[:works].first
      expect(work.id).to eq("https://dev.bcld.info/works/25305194-1115-43ab-8a7c-4ef586a1e8e5")
    end

    it "populates the work types" do
      work = result[:works].first
      expect(work.types).to include("Work", "Text", "Monograph")
    end

    it "populates the work title as a Title object" do
      work = result[:works].first
      expect(work.title).to be_a(BibframeRuby::Title)
      expect(work.title.main_title).to eq("The dungeon anarchist's cookbook")
    end

    it "populates the title non_sort_num" do
      work = result[:works].first
      expect(work.title.non_sort_num).to eq("4")
    end

    it "populates the work language" do
      work = result[:works].first
      expect(work.language).to eq("http://id.loc.gov/vocabulary/languages/eng")
    end

    it "populates genre_forms as URI strings" do
      work = result[:works].first
      expect(work.genre_forms).to include("http://id.loc.gov/authorities/genreForms/gf2014026339")
      expect(work.genre_forms.length).to eq(3)
    end

    it "populates the work summary" do
      work = result[:works].first
      expect(work.summary).to be_a(String)
      expect(work.summary).to include("Welcome to the Gun Show!")
    end

    it "populates contributions" do
      work = result[:works].first
      expect(work.contributions).to be_an(Array)
      expect(work.contributions.length).to eq(1)
    end

    it "creates Contribution objects with agent and role" do
      contribution = result[:works].first.contributions.first
      expect(contribution).to be_a(BibframeRuby::Contribution)
      expect(contribution.role).to eq("http://id.loc.gov/vocabulary/relators/aut")
    end

    it "marks primary contributions" do
      contribution = result[:works].first.contributions.first
      expect(contribution.primary?).to be true
    end

    it "creates a stub Resource for the agent URI" do
      agent = result[:works].first.contributions.first.agent
      expect(agent).to be_a(BibframeRuby::Resource)
      expect(agent.id).to eq("http://id.loc.gov/rwo/agents/no2023085548")
    end

    it "creates stub resources for hasInstance URIs" do
      work = result[:works].first
      expect(work.instances).to be_an(Array)
      expect(work.instances.length).to eq(1)
      expect(work.instances.first.id).to eq("https://dev.bcld.info/instances/4e0a7e08-b92a-46e5-8827-bdb635fef24a")
    end

    it "populates classifications" do
      work = result[:works].first
      expect(work.classifications).to be_an(Array)
      expect(work.classifications.length).to eq(2)
    end
  end

  context "with combined work and instance data" do
    let(:instance_jsonld) { File.read(File.join(__dir__, "fixtures/instance.jsonld")) }
    let(:combined_graph) do
      graph = rdf_graph
      BibframeRuby::Parser.new(instance_jsonld, format: :jsonld).parse.each_statement { |s| graph << s }
      graph
    end
    let(:combined_result) { described_class.new(combined_graph).build }

    it "creates both Work and Instance objects" do
      expect(combined_result[:works].length).to eq(1)
      expect(combined_result[:instances].length).to eq(1)
    end

    it "links work.instances to the hydrated Instance" do
      work = combined_result[:works].first
      instance = combined_result[:instances].first
      expect(work.instances.first).to eq(instance)
    end

    it "links instance.work to the hydrated Work" do
      work = combined_result[:works].first
      instance = combined_result[:instances].first
      expect(instance.work).to eq(work)
    end

    it "populates instance title" do
      instance = combined_result[:instances].first
      expect(instance.title).to be_a(BibframeRuby::Title)
      expect(instance.title.main_title).to eq("The dungeon anarchist's cookbook")
    end

    it "populates instance identifiers" do
      instance = combined_result[:instances].first
      expect(instance.identifiers).to be_an(Array)
      expect(instance.identifiers.length).to eq(2)
    end

    it "populates instance extent" do
      instance = combined_result[:instances].first
      expect(instance.extent).to eq("532 pages")
    end

    it "populates instance dimensions" do
      instance = combined_result[:instances].first
      expect(instance.dimensions).to eq("24 cm")
    end

    it "populates instance edition_statement" do
      instance = combined_result[:instances].first
      expect(instance.edition_statement).to eq("First Ace edition")
    end

    it "populates instance publication_statement" do
      instance = combined_result[:instances].first
      expect(instance.publication_statement).to eq("New York: Ace, 2024")
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/graph_builder_spec.rb`
Expected: FAIL with `uninitialized constant BibframeRuby::GraphBuilder`

- [ ] **Step 3: Implement GraphBuilder**

```ruby
# lib/bibframe_ruby/graph_builder.rb
# frozen_string_literal: true

module BibframeRuby
  class GraphBuilder
    BF = "http://id.loc.gov/ontologies/bibframe/"
    BFLC = "http://id.loc.gov/ontologies/bflc/"
    RDF_TYPE = RDF.type.to_s
    RDFS_LABEL = RDF::RDFS.label.to_s

    TYPE_MAP = {
      "#{BF}Work" => Work,
      "#{BF}Instance" => Instance,
      "#{BF}Item" => Item,
      "#{BF}Contribution" => Contribution,
      "#{BF}PrimaryContribution" => Contribution,
      "#{BF}Title" => Title,
      "#{BF}Person" => Person,
      "#{BF}Organization" => Organization,
      "#{BF}Subject" => Subject
    }.freeze

    # Maps BIBFRAME predicates to Ruby property names
    PROPERTY_MAP = {
      "#{BF}title" => "title",
      "#{BF}mainTitle" => "main_title",
      "#{BF}subtitle" => "subtitle",
      "#{BFLC}nonSortNum" => "non_sort_num",
      "#{BF}contribution" => "contributions",
      "#{BF}hasInstance" => "instances",
      "#{BF}instanceOf" => "work",
      "#{BF}hasItem" => "items",
      "#{BF}itemOf" => "instance",
      "#{BF}language" => "language",
      "#{BF}summary" => "summary",
      "#{BF}genreForm" => "genre_forms",
      "#{BF}classification" => "classifications",
      "#{BF}relation" => "relations",
      "#{BF}identifiedBy" => "identifiers",
      "#{BF}extent" => "extent",
      "#{BF}carrier" => "carrier",
      "#{BF}media" => "media",
      "#{BF}provisionActivity" => "provision_activity",
      "#{BF}editionStatement" => "edition_statement",
      "#{BF}dimensions" => "dimensions",
      "#{BF}publicationStatement" => "publication_statement",
      "#{BF}responsibilityStatement" => "responsibility_statement",
      "#{BF}issuance" => "issuance",
      "#{BF}agent" => "agent",
      "#{BF}role" => "role",
      "#{BF}heldBy" => "held_by",
      "#{BF}shelfMark" => "shelf_mark",
      "#{BF}content" => "content",
      "#{BF}subject" => "subjects",
      RDFS_LABEL => "label",
      "#{BF}code" => "code",
      "#{BF}source" => "source",
      "#{BF}status" => "status",
      "#{BF}date" => "date",
      "#{BF}seriesEnumeration" => "series_enumeration",
      "#{BF}associatedResource" => "associated_resource",
      "#{BF}relationship" => "relationship",
      "#{BF}adminMetadata" => "admin_metadata",
      "#{BF}derivedFrom" => "derived_from",
      "#{BF}assigner" => "assigner",
      "#{BF}classificationPortion" => "classification_portion",
      "#{BF}itemPortion" => "item_portion",
      "#{BF}edition" => "edition",
      "#{BF}descriptionLevel" => "description_level",
      "#{BF}descriptionLanguage" => "description_language",
      "#{BF}descriptionAuthentication" => "description_authentication",
      "#{BFLC}catalogerId" => "cataloger_id",
      "#{BFLC}aap" => "aap",
      "#{BFLC}aap-normalized" => "aap_normalized",
      "#{BFLC}simpleDate" => "simple_date",
      "#{BFLC}simpleAgent" => "simple_agent",
      "#{BFLC}simplePlace" => "simple_place"
    }.freeze

    # Properties that always hold arrays
    ARRAY_PROPERTIES = %w[
      contributions instances items genre_forms classifications
      relations identifiers subjects admin_metadata
    ].freeze

    def initialize(rdf_graph)
      @rdf_graph = rdf_graph
      @resources = {}
      @stubs = {}
    end

    def build
      grouped = group_by_subject
      extract_resources(grouped)
      link_relationships

      {
        resources: @resources,
        works: @resources.values.select { |r| r.is_a?(Work) },
        instances: @resources.values.select { |r| r.is_a?(Instance) },
        items: @resources.values.select { |r| r.is_a?(Item) }
      }
    end

    private

    def group_by_subject
      groups = Hash.new { |h, k| h[k] = [] }
      @rdf_graph.each_statement { |s| groups[s.subject] << s }
      groups
    end

    def extract_resources(grouped)
      grouped.each do |subject, statements|
        types = extract_types(statements)
        klass = resolve_class(types)
        type_names = types.map { |t| t.to_s.split("/").last }

        resource = klass.new(
          id: subject.is_a?(RDF::Node) ? nil : subject.to_s,
          types: type_names
        )

        populate_properties(resource, statements, grouped)
        register_resource(subject, resource)
      end
    end

    def extract_types(statements)
      statements
        .select { |s| s.predicate.to_s == RDF_TYPE }
        .map(&:object)
    end

    def resolve_class(types)
      types.each do |type|
        klass = TYPE_MAP[type.to_s]
        return klass if klass
      end
      Resource
    end

    def populate_properties(resource, statements, grouped)
      statements.each do |stmt|
        next if stmt.predicate.to_s == RDF_TYPE

        prop_name = PROPERTY_MAP[stmt.predicate.to_s] || stmt.predicate.to_s.split(%r{[/#]}).last
        value = resolve_value(stmt.object, grouped)

        if ARRAY_PROPERTIES.include?(prop_name)
          resource[prop_name] ||= []
          resource[prop_name] << value
        elsif resource[prop_name].nil?
          resource[prop_name] = value
        elsif resource[prop_name].is_a?(Array)
          resource[prop_name] << value
        else
          resource[prop_name] = [resource[prop_name], value]
        end
      end
    end

    def resolve_value(object, grouped)
      case object
      when RDF::Node
        # Blank nodes become inline resources built from their own statements
        if grouped.key?(object)
          sub_statements = grouped[object]
          types = extract_types(sub_statements)
          klass = resolve_class(types)
          type_names = types.map { |t| t.to_s.split("/").last }

          sub_resource = klass.new(types: type_names)
          populate_properties(sub_resource, sub_statements, grouped)
          register_resource(object, sub_resource)
          sub_resource
        end
      when RDF::URI
        object.to_s
      when RDF::Literal
        object.object
      else
        object.to_s
      end
    end

    def register_resource(subject, resource)
      key = subject.to_s
      @resources[key] = resource
    end

    def link_relationships
      link_work_instances
      link_instance_items
      replace_uri_stubs
    end

    def link_work_instances
      @resources.values.select { |r| r.is_a?(Work) }.each do |work|
        next unless work["instances"]

        work["instances"] = work["instances"].map do |ref|
          uri = ref.is_a?(String) ? ref : ref.id
          @resources[uri] || stub_for(uri)
        end
      end

      @resources.values.select { |r| r.is_a?(Instance) }.each do |instance|
        next unless instance["work"]

        uri = instance["work"].is_a?(String) ? instance["work"] : instance["work"].id
        instance["work"] = @resources[uri] || stub_for(uri)
      end
    end

    def link_instance_items
      @resources.values.select { |r| r.is_a?(Instance) }.each do |instance|
        next unless instance["items"]

        instance["items"] = instance["items"].map do |ref|
          uri = ref.is_a?(String) ? ref : ref.id
          @resources[uri] || stub_for(uri)
        end
      end

      @resources.values.select { |r| r.is_a?(Item) }.each do |item|
        next unless item["instance"]

        uri = item["instance"].is_a?(String) ? item["instance"] : item["instance"].id
        item["instance"] = @resources[uri] || stub_for(uri)
      end
    end

    def replace_uri_stubs
      # Replace any remaining string URI references in contribution agents
      @resources.values.select { |r| r.is_a?(Contribution) }.each do |contrib|
        next unless contrib["agent"].is_a?(String)

        contrib["agent"] = @resources[contrib["agent"]] || stub_for(contrib["agent"])
      end
    end

    def stub_for(uri)
      @stubs[uri] ||= Resource.new(id: uri)
    end
  end
end
```

- [ ] **Step 4: Update bibframe_ruby.rb to require graph_builder**

Add to `lib/bibframe_ruby.rb`:

```ruby
require_relative "bibframe_ruby/graph_builder"
```

- [ ] **Step 5: Run tests and verify they pass**

Run: `bundle exec rspec spec/graph_builder_spec.rb`
Expected: all pass. If any fail, debug using the triple output and adjust property mapping.

- [ ] **Step 6: Commit**

```bash
git add lib/bibframe_ruby/graph_builder.rb spec/graph_builder_spec.rb lib/bibframe_ruby.rb
git commit -m "feat: add GraphBuilder for RDF graph to model hydration"
```

---

### Task 5: Graph Container and Public API

Create the `Graph` wrapper and the `BibframeRuby.parse` / `.parse_file` entry points.

**Files:**
- Create: `lib/bibframe_ruby/graph.rb`
- Create: `spec/graph_spec.rb`
- Modify: `lib/bibframe_ruby.rb`
- Modify: `spec/bibframe_ruby_spec.rb`

**Interfaces:**
- Consumes: `BibframeRuby::Parser`, `BibframeRuby::GraphBuilder`
- Produces: `BibframeRuby.parse(input, format:)` and `BibframeRuby.parse_file(path)` both return `BibframeRuby::Graph`; `Graph#works`, `Graph#instances`, `Graph#items`, `Graph#resources`

- [ ] **Step 1: Write failing Graph spec**

```ruby
# spec/graph_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby::Graph do
  let(:work_jsonld) { File.read(File.join(__dir__, "fixtures/work.jsonld")) }
  let(:instance_jsonld) { File.read(File.join(__dir__, "fixtures/instance.jsonld")) }

  describe ".from_rdf" do
    it "creates a Graph from an RDF::Graph" do
      rdf_graph = BibframeRuby::Parser.new(work_jsonld, format: :jsonld).parse
      graph = described_class.from_rdf(rdf_graph)
      expect(graph).to be_a(described_class)
    end
  end

  describe "#works" do
    it "returns Work objects" do
      rdf_graph = BibframeRuby::Parser.new(work_jsonld, format: :jsonld).parse
      graph = described_class.from_rdf(rdf_graph)
      expect(graph.works).to be_an(Array)
      expect(graph.works.first).to be_a(BibframeRuby::Work)
    end
  end

  describe "#instances" do
    it "returns Instance objects" do
      rdf_graph = BibframeRuby::Parser.new(instance_jsonld, format: :jsonld).parse
      graph = described_class.from_rdf(rdf_graph)
      expect(graph.instances).to be_an(Array)
      expect(graph.instances.first).to be_a(BibframeRuby::Instance)
    end
  end

  describe "#resources" do
    it "returns all resources" do
      rdf_graph = BibframeRuby::Parser.new(work_jsonld, format: :jsonld).parse
      graph = described_class.from_rdf(rdf_graph)
      expect(graph.resources).to be_an(Array)
      expect(graph.resources.length).to be > 1
    end
  end
end
```

- [ ] **Step 2: Write failing integration spec**

Update `spec/bibframe_ruby_spec.rb`:

```ruby
# spec/bibframe_ruby_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby do
  it "has a version number" do
    expect(BibframeRuby::VERSION).not_to be_nil
  end

  describe ".parse" do
    let(:work_jsonld) { File.read(File.join(__dir__, "fixtures/work.jsonld")) }

    it "returns a Graph" do
      result = described_class.parse(work_jsonld, format: :jsonld)
      expect(result).to be_a(BibframeRuby::Graph)
    end

    it "parses works from JSON-LD" do
      result = described_class.parse(work_jsonld, format: :jsonld)
      expect(result.works.length).to eq(1)
    end

    it "defaults format to :jsonld" do
      result = described_class.parse(work_jsonld)
      expect(result.works.length).to eq(1)
    end
  end

  describe ".parse_file" do
    let(:fixture_path) { File.join(__dir__, "fixtures/work.jsonld") }

    it "returns a Graph" do
      result = described_class.parse_file(fixture_path)
      expect(result).to be_a(BibframeRuby::Graph)
    end

    it "detects format from file extension" do
      result = described_class.parse_file(fixture_path)
      expect(result.works.length).to eq(1)
    end
  end
end
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `bundle exec rspec spec/graph_spec.rb spec/bibframe_ruby_spec.rb`
Expected: FAIL with `uninitialized constant BibframeRuby::Graph` and `NoMethodError`

- [ ] **Step 4: Implement Graph**

```ruby
# lib/bibframe_ruby/graph.rb
# frozen_string_literal: true

module BibframeRuby
  class Graph
    attr_reader :works, :instances, :items, :resources

    def initialize(works:, instances:, items:, resources:)
      @works = works
      @instances = instances
      @items = items
      @resources = resources
    end

    def self.from_rdf(rdf_graph)
      result = GraphBuilder.new(rdf_graph).build
      new(
        works: result[:works],
        instances: result[:instances],
        items: result[:items],
        resources: result[:resources].values
      )
    end
  end
end
```

- [ ] **Step 5: Add public API methods and requires to bibframe_ruby.rb**

Update `lib/bibframe_ruby.rb` to its final form:

```ruby
# frozen_string_literal: true

require_relative "bibframe_ruby/version"
require_relative "bibframe_ruby/resource"
require_relative "bibframe_ruby/models/title"
require_relative "bibframe_ruby/models/work"
require_relative "bibframe_ruby/models/instance"
require_relative "bibframe_ruby/models/item"
require_relative "bibframe_ruby/models/contribution"
require_relative "bibframe_ruby/models/agent"
require_relative "bibframe_ruby/models/person"
require_relative "bibframe_ruby/models/organization"
require_relative "bibframe_ruby/models/subject"
require_relative "bibframe_ruby/parser"
require_relative "bibframe_ruby/graph_builder"
require_relative "bibframe_ruby/graph"

module BibframeRuby
  class Error < StandardError; end

  def self.parse(input, format: :jsonld)
    rdf_graph = Parser.new(input, format: format).parse
    Graph.from_rdf(rdf_graph)
  end

  def self.parse_file(path)
    ext = File.extname(path)
    format = Parser.format_for_extension(ext)
    input = File.read(path)
    parse(input, format: format)
  end
end
```

- [ ] **Step 6: Run all tests**

Run: `bundle exec rspec`
Expected: all pass

- [ ] **Step 7: Commit**

```bash
git add lib/bibframe_ruby.rb lib/bibframe_ruby/graph.rb spec/graph_spec.rb spec/bibframe_ruby_spec.rb
git commit -m "feat: add Graph container and public parse/parse_file API"
```

---

### Task 6: End-to-End Validation

Run the full suite, fix any issues, and verify the complete pipeline works against the fixture data.

**Files:**
- Possibly modify: any files from previous tasks if tests reveal issues

**Interfaces:**
- Consumes: everything from Tasks 1-5
- Produces: a green test suite

- [ ] **Step 1: Run the full test suite**

Run: `bundle exec rspec --format documentation`
Expected: all tests pass

- [ ] **Step 2: Verify in IRB**

Run: `bundle exec ruby -e '
require "bibframe_ruby"
result = BibframeRuby.parse_file("spec/fixtures/work.jsonld")
work = result.works.first
puts "Title: #{work.title.main_title}"
puts "Types: #{work.types.join(", ")}"
puts "Language: #{work.language}"
puts "Genre forms: #{work.genre_forms.length}"
puts "Contributions: #{work.contributions.length}"
puts "Primary? #{work.contributions.first.primary?}"
puts "Agent: #{work.contributions.first.agent.id}"
puts "Hash access: #{work["summary"]&.slice(0, 50)}"
'`

Expected: all values print correctly

- [ ] **Step 3: Fix any issues found, re-run tests**

If any tests fail or IRB output is wrong, debug and fix. Re-run `bundle exec rspec` to confirm.

- [ ] **Step 4: Commit any fixes**

```bash
git add -A
git commit -m "fix: resolve issues found during end-to-end validation"
```

Only commit if there were actual changes. Skip if everything passed cleanly.
