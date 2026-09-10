# frozen_string_literal: true

require "set"

# BibframeRuby::Resource: Base class for all BIBFRAME resource types
module BibframeRuby
  # Base class for all BIBFRAME resources. Provides URI identity, type tracking, and hash-style property access.
  class Resource
    attr_reader :id, :types
    attr_accessor :properties, :rdf_graph

    def initialize(id: nil, types: [], properties: {})
      @id = id
      @types = types
      @properties = properties
      @rdf_graph = nil
    end

    def [](key)
      @properties[key.to_s]
    end

    def []=(key, value)
      @properties[key.to_s] = value
    end

    def to_rdf(format: :jsonld)
      raise BibframeRuby::Error, "Unsupported serialization format: #{format}" unless Graph::WRITER_MAP.key?(format)
      raise BibframeRuby::Error, "No RDF graph available for serialization" unless @rdf_graph && @id

      sub_graph = extract_sub_graph
      Graph::WRITER_MAP[format].buffer(prefixes: Graph::PREFIXES.dup) { |w| sub_graph.each_statement { |s| w << s } }
    end

    private

    def extract_sub_graph
      sub_graph = RDF::Graph.new
      visited = Set.new
      collect_triples(RDF::URI(@id), visited, sub_graph)
      sub_graph
    end

    def collect_triples(subject, visited, sub_graph)
      return if visited.include?(subject)

      visited << subject
      @rdf_graph.query({subject: subject}).each do |stmt|
        sub_graph << stmt
        collect_triples(stmt.object, visited, sub_graph) if stmt.object.is_a?(RDF::Node)
      end
    end
  end
end
