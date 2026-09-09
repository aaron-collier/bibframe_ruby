# frozen_string_literal: true

require "json/ld"
require "rdf"
require "rdf/turtle"
require "rdf/rdfxml"

# BibframeRuby::Parser: Converts serialized RDF input into an RDF graph
module BibframeRuby
  # Parses serialized RDF input (JSON-LD, Turtle) into an RDF::Graph using the appropriate reader.
  class Parser
    EXTENSION_MAP = {
      ".jsonld" => :jsonld,
      ".ttl" => :turtle,
      ".rdf" => :rdfxml
    }.freeze

    READER_MAP = {
      jsonld: JSON::LD::Reader,
      turtle: RDF::Turtle::Reader,
      rdfxml: RDF::RDFXML::Reader
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
