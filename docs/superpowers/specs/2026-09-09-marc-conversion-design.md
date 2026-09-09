# MARC to BIBFRAME Conversion Design

## Overview

Add `BibframeRuby.convert_marc` to convert MARC records (binary MARC21 or MARCXML) into BIBFRAME Ruby objects. Uses the Library of Congress marc2bibframe2 XSLT stylesheets vendored into the gem, with Nokogiri for the XSLT transform and the `marc` gem for reading binary MARC.

## Public API

```ruby
# Convert from a MARC file path (binary .mrc or MARCXML .xml)
graph = BibframeRuby.convert_marc("record.mrc", baseuri: "http://example.org/")

# Same Graph object as parse/parse_file/parse_uri
graph.works      # => [Work, ...]
graph.instances  # => [Instance, ...]
```

### Parameters

- `path` -- file path to a binary MARC (.mrc) or MARCXML (.xml) file
- `baseuri:` -- base URI for minted resource URIs (default: `"http://example.org/"`)
- `idsource:` -- identifier for the converting agent (default: `nil`)

## Pipeline

1. `MarcConverter` reads the file and detects format (binary MARC vs MARCXML) by checking if content starts with digits (MARC leader) or `<` (XML)
2. If binary MARC, converts to MARCXML using the `marc` gem's `MARC::XMLWriter`
3. Applies the vendored marc2bibframe2 XSLT via Nokogiri, producing RDF/XML
4. Parses the RDF/XML into an `RDF::Graph` via the Parser (`:rdfxml` format)
5. Feeds into the existing `Graph.from_rdf` pipeline

## Components

### MarcConverter (`lib/bibframe_ruby/marc_converter.rb`)

Owns the MARC-to-RDF/XML conversion:

- `MarcConverter.new(input, baseuri:, idsource:)` -- accepts file content as a string
- `#convert` -- returns RDF/XML string
- Detects binary MARC vs MARCXML by inspecting content
- Converts binary MARC to MARCXML via `marc` gem
- Loads and caches the vendored XSLT stylesheet (compiled once per process via class-level memoization)
- Transforms MARCXML to RDF/XML via Nokogiri XSLT
- Passes `baseuri` and `idsource` as XSLT parameters

### Parser changes

Add `:rdfxml` to `READER_MAP` with `RDF::RDFXML::Reader`, and `require "rdf/rdfxml"`. This follows the same pattern as the Turtle addition and also enables `parse_file("something.rdf")`.

### Entry point

`BibframeRuby.convert_marc(path, baseuri:, idsource:)` in `lib/bibframe_ruby.rb`:

```ruby
def self.convert_marc(path, baseuri: "http://example.org/", idsource: nil)
  input = File.read(path)
  rdfxml = MarcConverter.new(input, baseuri: baseuri, idsource: idsource).convert
  parse(rdfxml, format: :rdfxml)
end
```

## Vendored Assets

`vendor/marc2bibframe2/xsl/` -- the full `xsl/` directory from lcnetdev/marc2bibframe2 at a specific release tag. Includes:

- `marc2bibframe2.xsl` -- main entry stylesheet
- `variables.xsl`, `utils.xsl` -- shared utilities
- `ConvSpec-*.xsl` -- ~20 conversion spec files
- `conf/` -- lookup tables (subjectThesaurus.xml, codeMaps.xml, etc.)

The stylesheets are CC0 licensed.

## New Dependencies

- `nokogiri` -- XSLT 1.0 transformation via libxslt
- `marc` -- reading binary MARC21 records and converting to MARCXML

Both added to the gemspec as runtime dependencies.

## File Structure

```
vendor/
  marc2bibframe2/
    xsl/                          # Vendored from lcnetdev/marc2bibframe2
      marc2bibframe2.xsl
      variables.xsl
      utils.xsl
      ConvSpec-*.xsl
      conf/
lib/
  bibframe_ruby.rb                # Add convert_marc, require marc_converter
  bibframe_ruby/
    parser.rb                     # Add rdfxml to READER_MAP
    marc_converter.rb             # New: MARC to RDF/XML conversion
spec/
  fixtures/
    record.mrc                    # Binary MARC fixture
  bibframe_ruby/
    marc_converter_spec.rb        # MarcConverter unit tests
    parser_rdfxml_spec.rb         # RDF/XML reader tests
  convert_marc_spec.rb            # Integration tests
```

## Testing Strategy

- **MarcConverter spec** -- detects binary MARC vs MARCXML, converts binary to MARCXML, applies XSLT to produce valid RDF/XML, passes baseuri/idsource parameters
- **Parser RDF/XML spec** -- verifies the new :rdfxml reader works (same pattern as Turtle spec)
- **Integration spec** -- `BibframeRuby.convert_marc(path)` returns a Graph with Works, Instances, titles
- All tests use local fixtures and vendored stylesheets, no network calls
