# BibframeRuby

A Ruby gem for parsing [BIBFRAME](https://www.loc.gov/bibframe/) data into Ruby objects. Currently supports JSON-LD, with Turtle and RDF/XML support planned.

Built on the [RDF.rb](https://github.com/ruby-rdf/rdf) ecosystem, BibframeRuby converts BIBFRAME documents into typed Ruby objects with idiomatic accessors and linked relationships.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "bibframe_ruby"
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install bibframe_ruby
```

## Usage

### Parsing JSON-LD

```ruby
require "bibframe_ruby"

# Parse a JSON-LD string
json = File.read("work.jsonld")
graph = BibframeRuby.parse(json)

# Or parse directly from a file (format detected from extension)
graph = BibframeRuby.parse_file("work.jsonld")

# Parse from a remote URI (fetches the content)
graph = BibframeRuby.parse_uri("https://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac.jsonld")
```

### Accessing Resources

The returned `Graph` provides typed collections:

```ruby
graph.works      # => [BibframeRuby::Work, ...]
graph.instances  # => [BibframeRuby::Instance, ...]
graph.items      # => [BibframeRuby::Item, ...]
graph.hubs       # => [BibframeRuby::Hub, ...]
graph.resources  # => all parsed resources
```

### Working with a Work

```ruby
work = graph.works.first

work.id
# => "https://dev.bcld.info/works/25305194-1115-43ab-8a7c-4ef586a1e8e5"

work.types
# => ["Monograph", "Text", "Work"]

work.title.main_title
# => "The dungeon anarchist's cookbook"

work.title.non_sort_num
# => "4"

work.language
# => "http://id.loc.gov/vocabulary/languages/eng"

work.genre_forms
# => ["http://id.loc.gov/authorities/genreForms/gf2023026123", ...]

work.summary
# => "\"Welcome to the Gun Show! The top ten list is populated..."

work.classifications.length
# => 2
```

### Contributions

```ruby
contribution = work.contributions.first

contribution.primary?
# => true

contribution.role
# => "http://id.loc.gov/vocabulary/relators/aut"

contribution.agent.id
# => "http://id.loc.gov/rwo/agents/no2023085548"
```

### Working with an Instance

When you parse both a Work and its Instance, the relationships are automatically linked:

```ruby
instance = graph.instances.first

instance.title.main_title
# => "The dungeon anarchist's cookbook"

instance.extent
# => "532 pages"

instance.dimensions
# => "24 cm"

instance.edition_statement
# => "First Ace edition"

instance.publication_statement
# => "New York: Ace, 2024"

# Bidirectional linking
instance.work.title.main_title
# => "The dungeon anarchist's cookbook"

work.instances.first == instance
# => true
```

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

### Identifiers

```ruby
instance.identifiers.length
# => 2

lccn = instance.identifiers.find { |id| id.types.include?("Lccn") }
isbn = instance.identifiers.find { |id| id.types.include?("Isbn") }
```

### Hash-Style Property Access

Any property can be accessed by name, even if there is no named accessor:

```ruby
work["language"]
# => "http://id.loc.gov/vocabulary/languages/eng"

work["aap"]
# => "Dinniman, Matt. The dungeon anarchist's cookbook"
```

### Combining Multiple Documents

To parse related documents together (e.g., a Work and its Instance), combine their RDF graphs before building:

```ruby
work_graph = BibframeRuby::Parser.new(work_json, format: :jsonld).parse
instance_graph = BibframeRuby::Parser.new(instance_json, format: :jsonld).parse

# Merge statements into one graph
instance_graph.each_statement { |s| work_graph << s }

# Build with linked relationships
result = BibframeRuby::Graph.from_rdf(work_graph)

result.works.first.instances.first.extent
# => "532 pages"
```

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

### Stub Resources

When a parsed document references an external resource by URI (e.g., an agent in the Library of Congress), a stub `Resource` is created with just the `id` set:

```ruby
agent = work.contributions.first.agent
agent.id
# => "http://id.loc.gov/rwo/agents/no2023085548"

agent.is_a?(BibframeRuby::Resource)
# => true
```

### Serializing to RDF

Serialize a graph or individual resource back to JSON-LD or Turtle:

```ruby
# Serialize the entire graph to JSON-LD (default)
puts graph.to_rdf

# Serialize to Turtle
puts graph.to_rdf(format: :turtle)

# Serialize a single resource (includes its nested blank nodes)
puts work.to_rdf
puts work.to_rdf(format: :turtle)
```

Output includes BIBFRAME-aware prefixes (`bf:`, `bflc:`, `rdfs:`, etc.) for readable output.

## Model Reference

| Class | Accessors |
|-------|-----------|
| `Resource` | `id`, `types`, `properties`, `[]`, `[]=`, `to_rdf` |
| `Work` | `title`, `contributions`, `instances`, `language`, `subjects`, `genre_forms`, `summary`, `classifications`, `relations` |
| `Instance` | `title`, `work`, `identifiers`, `extent`, `carrier`, `media`, `provision_activity`, `edition_statement`, `dimensions`, `publication_statement`, `items` |
| `Hub` | `title`, `contributions`, `language`, `identifiers`, `relations`, `label` |
| `Item` | `instance`, `held_by`, `shelf_mark` |
| `Contribution` | `agent`, `role`, `primary?` |
| `Title` | `main_title`, `subtitle`, `non_sort_num` |
| `Agent` | `label` |
| `Person` | `label` (inherits from Agent) |
| `Organization` | `label` (inherits from Agent) |
| `Subject` | `label`, `source` |

All models inherit from `Resource` and support hash-style access via `[]` for any property.

## Supported Formats

| Format | Status | File Extension |
|--------|--------|----------------|
| JSON-LD | Supported | `.jsonld` |
| Turtle | Supported | `.ttl` |
| RDF/XML | Supported | `.rdf` |
| MARC21 (binary) | Supported (convert) | `.mrc` |
| MARCXML | Supported (convert) | `.xml` |

## Development

After checking out the repo, run `bin/setup` to install dependencies.

### Running Tests

```bash
bundle exec rspec
```

With documentation output:

```bash
bundle exec rspec --format documentation
```

### Console

You can run `bin/console` for an interactive prompt to experiment with the gem.

## Requirements

- Ruby >= 3.2.0

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aaron-collier/bibframe_ruby.
