# Hub Model and parse_uri Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Hub model class and a `parse_uri` method that fetches BIBFRAME JSON-LD from a URL and parses it.

**Architecture:** Hub is a new model subclass following existing patterns. The GraphBuilder TYPE_MAP needs Hub added before Work so Hub takes priority when both types are present (Hubs have types `[Work, Hub, ...]`). `parse_uri` uses `net/http` to fetch content, then delegates to the existing `parse` pipeline.

**Tech Stack:** Ruby 3.2+, RSpec, `net/http` (stdlib), `json-ld` gem, `rdf` gem

**Spec:** Bounded design approved in chat — no separate spec document.

## Global Constraints

- Ruby >= 3.2.0
- All files use `# frozen_string_literal: true`
- BIBFRAME namespace: `http://id.loc.gov/ontologies/bibframe/`
- BFLC namespace: `http://id.loc.gov/ontologies/bflc/`
- Conventional commits
- TDD: write failing tests first, then implement

---

### Task 1: Hub Model and GraphBuilder Integration

Add the Hub model class, its fixture, register it in GraphBuilder's TYPE_MAP (before Work so it takes priority), add `Graph#hubs`, and update the entry point requires.

**Files:**
- Create: `lib/bibframe_ruby/models/hub.rb`
- Create: `spec/models/hub_spec.rb`
- Create: `spec/fixtures/hub.jsonld`
- Create: `spec/graph_builder_hub_spec.rb`
- Modify: `lib/bibframe_ruby/graph_builder.rb` (TYPE_MAP, build method)
- Modify: `lib/bibframe_ruby/graph.rb` (add hubs accessor)
- Modify: `lib/bibframe_ruby.rb` (add require, no new public methods)

**Interfaces:**
- Consumes: `BibframeRuby::Resource` base class, `BibframeRuby::GraphBuilder`, `BibframeRuby::Graph`
- Produces: `BibframeRuby::Hub` (`#title`, `#contributions`, `#language`, `#identifiers`, `#relations`, `#label`), `BibframeRuby::Graph#hubs` returns `[Hub, ...]`, `GraphBuilder#build` returns hash with additional `:hubs` key

- [ ] **Step 1: Download the Hub fixture**

```bash
curl -sL 'https://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac.jsonld' | ruby -rjson -e 'puts JSON.pretty_generate(JSON.parse(STDIN.read))' > spec/fixtures/hub.jsonld
```

- [ ] **Step 2: Write failing Hub model spec**

```ruby
# spec/models/hub_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby::Hub do
  subject(:hub) do
    described_class.new(
      id: "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac",
      types: ["Work", "Hub", "Series"],
      properties: {
        "title" => title,
        "contributions" => [contribution],
        "language" => "http://id.loc.gov/vocabulary/languages/eng",
        "identifiers" => [],
        "relations" => [],
        "label" => "Dinniman, Matt. Dungeon crawler Carl (Series)"
      }
    )
  end

  let(:title) { BibframeRuby::Title.new(properties: { "main_title" => "Dungeon crawler Carl (Series)" }) }
  let(:contribution) { BibframeRuby::Contribution.new(properties: { "role" => "ctb", "primary" => true }) }

  it "inherits from Resource" do
    expect(hub).to be_a(BibframeRuby::Resource)
  end

  describe "#title" do
    it "returns the Title object" do
      expect(hub.title).to eq(title)
    end
  end

  describe "#contributions" do
    it "returns the contributions array" do
      expect(hub.contributions).to eq([contribution])
    end
  end

  describe "#language" do
    it "returns the language" do
      expect(hub.language).to eq("http://id.loc.gov/vocabulary/languages/eng")
    end
  end

  describe "#identifiers" do
    it "returns the identifiers array" do
      expect(hub.identifiers).to eq([])
    end
  end

  describe "#relations" do
    it "returns the relations array" do
      expect(hub.relations).to eq([])
    end
  end

  describe "#label" do
    it "returns the label" do
      expect(hub.label).to eq("Dinniman, Matt. Dungeon crawler Carl (Series)")
    end
  end
end
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bundle exec rspec spec/models/hub_spec.rb`
Expected: FAIL with `uninitialized constant BibframeRuby::Hub`

- [ ] **Step 4: Implement Hub model**

```ruby
# lib/bibframe_ruby/models/hub.rb
# frozen_string_literal: true

module BibframeRuby
  class Hub < Resource
    def title
      self["title"]
    end

    def contributions
      self["contributions"] || []
    end

    def language
      self["language"]
    end

    def identifiers
      self["identifiers"] || []
    end

    def relations
      self["relations"] || []
    end

    def label
      self["label"]
    end
  end
end
```

- [ ] **Step 5: Add require to lib/bibframe_ruby.rb**

Add after the `require_relative "bibframe_ruby/models/subject"` line:

```ruby
require_relative "bibframe_ruby/models/hub"
```

- [ ] **Step 6: Run Hub model spec and verify it passes**

Run: `bundle exec rspec spec/models/hub_spec.rb`
Expected: all pass

- [ ] **Step 7: Write failing GraphBuilder Hub spec**

```ruby
# spec/graph_builder_hub_spec.rb
# frozen_string_literal: true

RSpec.describe BibframeRuby::GraphBuilder do
  let(:hub_jsonld) { File.read(File.join(__dir__, "fixtures/hub.jsonld")) }
  let(:rdf_graph) { BibframeRuby::Parser.new(hub_jsonld, format: :jsonld).parse }
  let(:result) { described_class.new(rdf_graph).build }

  describe "Hub parsing" do
    it "returns a hash with hubs array" do
      expect(result[:hubs]).to be_an(Array)
      expect(result[:hubs].length).to be >= 1
    end

    it "creates a Hub instance for bf:Hub typed resources" do
      hub = result[:hubs].first
      expect(hub).to be_a(BibframeRuby::Hub)
    end

    it "does not create a Work for Hub-typed resources" do
      works = result[:works]
      hub_uri = "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac"
      expect(works.map(&:id)).not_to include(hub_uri)
    end

    it "sets the hub id" do
      hub = result[:hubs].find { |h| h.id == "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac" }
      expect(hub).not_to be_nil
    end

    it "populates the hub types" do
      hub = result[:hubs].find { |h| h.id == "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac" }
      expect(hub.types).to include("Hub", "Work", "Series")
    end

    it "populates the hub title as a Title object" do
      hub = result[:hubs].find { |h| h.id == "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac" }
      expect(hub.title).to be_a(BibframeRuby::Title)
      expect(hub.title.main_title).to eq("Dungeon crawler Carl (Series)")
    end

    it "populates hub contributions" do
      hub = result[:hubs].find { |h| h.id == "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac" }
      expect(hub.contributions).to be_an(Array)
      expect(hub.contributions.length).to eq(1)
      expect(hub.contributions.first).to be_a(BibframeRuby::Contribution)
      expect(hub.contributions.first.primary?).to be true
    end

    it "populates hub identifiers" do
      hub = result[:hubs].find { |h| h.id == "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac" }
      expect(hub.identifiers).to be_an(Array)
      expect(hub.identifiers.length).to eq(2)
    end

    it "populates hub relations" do
      hub = result[:hubs].find { |h| h.id == "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac" }
      expect(hub.relations).to be_an(Array)
      expect(hub.relations.length).to eq(1)
    end

    it "hydrates named URI resources like Person from the document" do
      agent = result[:resources].values.find { |r| r.is_a?(BibframeRuby::Person) }
      expect(agent).not_to be_nil
      expect(agent.label).to eq("Dinniman, Matt")
    end
  end
end
```

- [ ] **Step 8: Run test to verify it fails**

Run: `bundle exec rspec spec/graph_builder_hub_spec.rb`
Expected: FAIL — `result[:hubs]` is nil because GraphBuilder doesn't return hubs yet

- [ ] **Step 9: Update GraphBuilder**

In `lib/bibframe_ruby/graph_builder.rb`, make two changes:

**Change 1:** In `TYPE_MAP`, add Hub *before* Work so it takes priority when both types are present:

Replace the TYPE_MAP constant:

```ruby
TYPE_MAP = {
  "#{BF}Hub" => Hub,
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
```

**Change 2:** In the `build` method, add `:hubs` to the return hash:

```ruby
def build
  grouped = group_by_subject
  extract_resources(grouped)
  link_relationships

  {
    resources: @resources,
    works: @resources.values.select { |r| r.is_a?(Work) && !r.is_a?(Hub) },
    instances: @resources.values.select { |r| r.is_a?(Instance) },
    items: @resources.values.select { |r| r.is_a?(Item) },
    hubs: @resources.values.select { |r| r.is_a?(Hub) }
  }
end
```

Note: Hub does NOT inherit from Work — it inherits from Resource. So the `works` filter does not need `!r.is_a?(Hub)`. But since Hub has `bf:Work` in its types, it will be instantiated as Hub (not Work) because Hub comes first in TYPE_MAP. The `works` filter `r.is_a?(Work)` will not match Hub instances. The filter is correct as-is without the guard. So the actual build method is:

```ruby
def build
  grouped = group_by_subject
  extract_resources(grouped)
  link_relationships

  {
    resources: @resources,
    works: @resources.values.select { |r| r.is_a?(Work) },
    instances: @resources.values.select { |r| r.is_a?(Instance) },
    items: @resources.values.select { |r| r.is_a?(Item) },
    hubs: @resources.values.select { |r| r.is_a?(Hub) }
  }
end
```

- [ ] **Step 10: Update Graph to include hubs**

In `lib/bibframe_ruby/graph.rb`:

```ruby
# frozen_string_literal: true

module BibframeRuby
  class Graph
    attr_reader :works, :instances, :items, :hubs, :resources

    def initialize(works:, instances:, items:, hubs:, resources:)
      @works = works
      @instances = instances
      @items = items
      @hubs = hubs
      @resources = resources
    end

    def self.from_rdf(rdf_graph)
      result = GraphBuilder.new(rdf_graph).build
      new(
        works: result[:works],
        instances: result[:instances],
        items: result[:items],
        hubs: result[:hubs],
        resources: result[:resources].values
      )
    end
  end
end
```

- [ ] **Step 11: Run all tests and verify they pass**

Run: `bundle exec rspec`
Expected: all pass (existing tests should still pass since Hub inherits from Resource not Work)

- [ ] **Step 12: Commit**

```bash
git add lib/bibframe_ruby/models/hub.rb spec/models/hub_spec.rb spec/fixtures/hub.jsonld spec/graph_builder_hub_spec.rb lib/bibframe_ruby/graph_builder.rb lib/bibframe_ruby/graph.rb lib/bibframe_ruby.rb
git commit -m "feat: add Hub model class with GraphBuilder and Graph integration"
```

---

### Task 2: parse_uri Method

Add `BibframeRuby.parse_uri(uri)` that fetches JSON-LD from a URL and parses it.

**Files:**
- Create: `spec/parse_uri_spec.rb`
- Modify: `lib/bibframe_ruby.rb` (add `self.parse_uri`)

**Interfaces:**
- Consumes: `BibframeRuby.parse(input, format:)`, `BibframeRuby::Parser.format_for_extension(ext)`
- Produces: `BibframeRuby.parse_uri(uri)` returns `BibframeRuby::Graph`

- [ ] **Step 1: Write failing parse_uri spec**

```ruby
# spec/parse_uri_spec.rb
# frozen_string_literal: true

require "net/http"

RSpec.describe BibframeRuby do
  describe ".parse_uri" do
    let(:hub_jsonld) { File.read(File.join(__dir__, "fixtures/hub.jsonld")) }
    let(:hub_uri) { "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac.jsonld" }

    before do
      stub_response = instance_double(Net::HTTPOK, body: hub_jsonld, is_a?: true)
      allow(stub_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(Net::HTTP).to receive(:get_response).and_return(stub_response)
    end

    it "returns a Graph" do
      result = described_class.parse_uri(hub_uri)
      expect(result).to be_a(BibframeRuby::Graph)
    end

    it "parses resources from the fetched content" do
      result = described_class.parse_uri(hub_uri)
      expect(result.hubs.length).to be >= 1
    end

    it "detects format from the URI extension" do
      result = described_class.parse_uri(hub_uri)
      hub = result.hubs.find { |h| h.id == "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac" }
      expect(hub).not_to be_nil
      expect(hub.title.main_title).to eq("Dungeon crawler Carl (Series)")
    end

    it "raises on HTTP errors" do
      error_response = instance_double(Net::HTTPNotFound, code: "404", message: "Not Found")
      allow(error_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(Net::HTTP).to receive(:get_response).and_return(error_response)

      expect { described_class.parse_uri(hub_uri) }.to raise_error(BibframeRuby::Error, /HTTP error: 404/)
    end

    it "defaults to jsonld format when URI has no extension" do
      no_ext_uri = "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac"
      result = described_class.parse_uri(no_ext_uri)
      expect(result).to be_a(BibframeRuby::Graph)
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/parse_uri_spec.rb`
Expected: FAIL with `NoMethodError: undefined method 'parse_uri'`

- [ ] **Step 3: Implement parse_uri**

Add to `lib/bibframe_ruby.rb`, after the existing `self.parse_file` method and add the `require` at the top of the file:

Add at the top of the file (after the other requires, before the module):

```ruby
require "net/http"
require "uri"
```

Add the method inside the module:

```ruby
def self.parse_uri(uri)
  parsed_uri = URI.parse(uri)
  response = Net::HTTP.get_response(parsed_uri)

  unless response.is_a?(Net::HTTPSuccess)
    raise Error, "HTTP error: #{response.code} #{response.message}"
  end

  ext = File.extname(parsed_uri.path)
  format = ext.empty? ? :jsonld : Parser.format_for_extension(ext)
  parse(response.body, format: format)
end
```

- [ ] **Step 4: Run tests and verify they pass**

Run: `bundle exec rspec spec/parse_uri_spec.rb`
Expected: all pass

- [ ] **Step 5: Run full test suite**

Run: `bundle exec rspec`
Expected: all pass

- [ ] **Step 6: Commit**

```bash
git add lib/bibframe_ruby.rb spec/parse_uri_spec.rb
git commit -m "feat: add parse_uri method for fetching and parsing remote BIBFRAME documents"
```

---

### Task 3: Update README

Add Hub and parse_uri documentation to the README.

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: everything from Tasks 1-2
- Produces: updated documentation

- [ ] **Step 1: Read the current README**

Read `README.md` to understand the existing structure.

- [ ] **Step 2: Add Hub documentation**

After the "Working with an Instance" section and before "Identifiers", add a "Working with a Hub" section:

```markdown
### Working with a Hub

Hubs are abstract resources that bridge between Works — commonly used for authority-linked title/author combinations.

```ruby
graph = BibframeRuby.parse_file("hub.jsonld")
hub = graph.hubs.first

hub.id
# => "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac"

hub.types
# => ["Work", "Hub", "Series"]

hub.title.main_title
# => "Dungeon crawler Carl (Series)"

hub.contributions.first.primary?
# => true

hub.relations.length
# => 1
```
```

Add `Hub` to the Model Reference table:

```
| `Hub` | `title`, `contributions`, `language`, `identifiers`, `relations`, `label` |
```

- [ ] **Step 3: Add parse_uri documentation**

In the "Parsing JSON-LD" section, after the `parse_file` example, add:

```markdown
```ruby
# Parse from a remote URI (fetches the content)
graph = BibframeRuby.parse_uri("https://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac.jsonld")
```
```

Also add `Graph#hubs` to the collections example:

```ruby
graph.hubs       # => [BibframeRuby::Hub, ...]
```

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add Hub model and parse_uri to README"
```
