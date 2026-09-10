# frozen_string_literal: true

require "json"
require "rdf/isomorphic"

# BibframeRuby::Graph: Container for parsed BIBFRAME resources with typed collection accessors
module BibframeRuby
  # Container returned by BibframeRuby.parse that holds all parsed resources with typed collection accessors.
  class Graph
    attr_reader :works, :instances, :items, :hubs, :resources, :rdf_graph

    WRITER_MAP = {
      jsonld: JSON::LD::Writer,
      turtle: RDF::Turtle::Writer
    }.freeze

    PREFIXES = {
      bf: "http://id.loc.gov/ontologies/bibframe/",
      bflc: "http://id.loc.gov/ontologies/bflc/",
      rdfs: "http://www.w3.org/2000/01/rdf-schema#",
      rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
      xsd: "http://www.w3.org/2001/XMLSchema#"
    }.freeze

    def initialize(works:, instances:, items:, resources:, hubs: [], rdf_graph: nil)
      @works = works
      @instances = instances
      @items = items
      @hubs = hubs
      @resources = resources
      @rdf_graph = rdf_graph
    end

    def ==(other)
      other.is_a?(Graph) && @rdf_graph.isomorphic_with?(other.rdf_graph)
    end

    def to_rdf(format: :jsonld)
      writer_class = WRITER_MAP.fetch(format) do
        raise BibframeRuby::Error, "Unsupported serialization format: #{format}"
      end

      writer_class.buffer(prefixes: PREFIXES.dup) { |w| @rdf_graph.each_statement { |s| w << s } }
    end

    def self.from_rdf(rdf_graph)
      result = GraphBuilder.new(rdf_graph).build

      graph = new(
        works: result[:works],
        instances: result[:instances],
        items: result[:items],
        hubs: result[:hubs],
        resources: result[:resources].values,
        rdf_graph: rdf_graph
      )

      # Set back-references so resources can serialize themselves
      result[:resources].each_value { |r| r.rdf_graph = rdf_graph }

      graph
    end
  end
end
