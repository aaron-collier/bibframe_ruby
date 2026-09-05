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
