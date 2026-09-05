# BIBFRAME JSON-LD Parsing Design

## Overview

Add JSON-LD parsing to the bibframe_ruby gem, producing Ruby objects that represent BIBFRAME resources with idiomatic accessors and bidirectional relationships. The parsing pipeline is built on the RDF gem stack so that adding Turtle and RDF-XML support later requires only swapping the reader.

## Entry Point

```ruby
# Parse a JSON-LD string
result = BibframeRuby.parse(jsonld_string, format: :jsonld)

# Parse from a file (format detected from extension)
result = BibframeRuby.parse_file("path/to/work.jsonld")
```

Both return a `BibframeRuby::Graph` instance:

```ruby
result.works      # => [Work, ...]
result.instances  # => [Instance, ...]
result.items      # => [Item, ...]
result.resources  # => all resources
```

The `format:` parameter defaults to `:jsonld`. Future values: `:turtle`, `:rdfxml`.

## Models

All models inherit from `BibframeRuby::Resource`.

### Resource (base class)

- `id` -- the URI string
- `types` -- array of RDF types (e.g., `["Work", "Text", "Monograph"]`)
- `properties` -- hash of all parsed properties
- `[]` / `[]=` -- hash-style access for any property

### Work

Named accessors: `title`, `contributions`, `instances`, `language`, `subjects`, `genre_forms`, `summary`, `classifications`, `relations`

### Instance

Named accessors: `title`, `work`, `identifiers`, `extent`, `carrier`, `media`, `provision_activity`, `edition_statement`, `dimensions`, `publication_statement`, `items`

### Item

Named accessors: `instance`, `held_by`, `shelf_mark`

### Contribution

Named accessors: `agent`, `role`, `primary?`

### Title

Named accessors: `main_title`, `subtitle`, `non_sort_num`

### Agent / Person / Organization

Named accessors: `label`, `id` (URI to authority record)

Person and Organization inherit from Agent.

### Subject

Named accessors: `label`, `source`

### Property behavior

- Single-valued properties return the object directly.
- Multi-valued properties return arrays.
- References to other BIBFRAME resources return the hydrated Ruby object, or a stub `Resource` with just the `id` if the target was not in the parsed data.

## Parsing Pipeline

### Stage 1: RDF Parsing (`Parser`)

Accepts raw input string and a format keyword. Delegates to the appropriate RDF reader:

- `:jsonld` -- `JSON::LD::Reader`
- `:turtle` -- `RDF::Turtle::Reader` (future)
- `:rdfxml` -- `RDF::RDFXML::Reader` (future)

Produces an `RDF::Graph`.

When using `parse_file`, format is detected from the file extension (`.jsonld`, `.ttl`, `.rdf`).

### Stage 2: Resource Extraction (`GraphBuilder`)

Walks the RDF graph:

1. Groups triples by subject URI.
2. Reads `rdf:type` triples to determine the model class.
3. Instantiates the appropriate model, populating properties from remaining triples.
4. Unrecognized types become plain `Resource` instances.

Type-to-class mapping:

```ruby
TYPE_MAP = {
  "http://id.loc.gov/ontologies/bibframe/Work" => Work,
  "http://id.loc.gov/ontologies/bibframe/Instance" => Instance,
  "http://id.loc.gov/ontologies/bibframe/Item" => Item,
  "http://id.loc.gov/ontologies/bibframe/Contribution" => Contribution,
  "http://id.loc.gov/ontologies/bibframe/PrimaryContribution" => Contribution,
  "http://id.loc.gov/ontologies/bibframe/Title" => Title,
  "http://id.loc.gov/ontologies/bibframe/Person" => Person,
  "http://id.loc.gov/ontologies/bibframe/Organization" => Organization,
  "http://id.loc.gov/ontologies/bibframe/Subject" => Subject,
}
```

### Stage 3: Relationship Linking (`GraphBuilder`)

Second pass after all resources are instantiated:

- `work.instances` <-> `instance.work` (via `bf:hasInstance` / `bf:instanceOf`)
- `instance.items` <-> `item.instance` (via `bf:hasItem` / `bf:itemOf`)
- `work.contributions` -> hydrated `Contribution` objects with `agent` resolved
- URI references to resources not in the parsed data become stub `Resource` objects with only `id` set

Optional resolution of external URIs is available but not enabled by default.

## File Structure

```
lib/
  bibframe_ruby.rb                  # Entry point: .parse, .parse_file
  bibframe_ruby/
    version.rb
    graph.rb                        # Graph container
    parser.rb                       # Stage 1: RDF parsing, format detection
    graph_builder.rb                # Stages 2 & 3: extraction + linking
    resource.rb                     # Base class
    models/
      work.rb
      instance.rb
      item.rb
      contribution.rb
      agent.rb
      person.rb
      organization.rb
      title.rb
      subject.rb
spec/
  bibframe_ruby_spec.rb
  fixtures/
    work.jsonld
    instance.jsonld
  parser_spec.rb
  graph_builder_spec.rb
  graph_spec.rb
  models/
    work_spec.rb
    instance_spec.rb
    item_spec.rb
    contribution_spec.rb
    title_spec.rb
    agent_spec.rb
    subject_spec.rb
```

## Testing Strategy

RSpec with real JSON-LD fixtures (the sample work and instance documents). No mocking of the RDF parsing layer.

### Test layers

1. **Parser specs** -- JSON-LD string produces a valid `RDF::Graph`. Format detection from file extension works.
2. **GraphBuilder specs** -- `RDF::Graph` produces correct model objects with correct types. Linking pass wires up bidirectional relationships. Stubs created for unresolved URIs.
3. **Graph specs** -- Integration tests through `BibframeRuby.parse`. `.works`, `.instances`, `.resources` return correct collections.
4. **Model specs** -- Named accessors return correct values from fixture data. Hash-style access works. Examples:
   - `work.title.main_title` -> `"The dungeon anarchist's cookbook"`
   - `work.contributions.first.primary?` -> `true`
   - `instance.identifiers` includes ISBN and LCCN
   - `work["genreForm"]` returns genre form data

TDD: specs written before implementation for each component.
