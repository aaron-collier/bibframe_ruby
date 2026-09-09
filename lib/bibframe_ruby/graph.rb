# frozen_string_literal: true

# BibframeRuby::Graph: Container for parsed BIBFRAME resources with typed collection accessors
module BibframeRuby
  # Container returned by BibframeRuby.parse that holds all parsed resources with typed collection accessors.
  class Graph
    attr_reader :works, :instances, :items, :hubs, :resources

    def initialize(works:, instances:, items:, resources:, hubs: [])
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
