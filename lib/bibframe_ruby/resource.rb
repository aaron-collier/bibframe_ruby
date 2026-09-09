# frozen_string_literal: true

# BibframeRuby::Resource: Base class for all BIBFRAME resource types
module BibframeRuby
  # Base class for all BIBFRAME resources. Provides URI identity, type tracking, and hash-style property access.
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
