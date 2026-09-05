# frozen_string_literal: true

module BibframeRuby
  class Instance < Resource
    def title
      self["title"]
    end

    def work
      self["work"]
    end

    def identifiers
      self["identifiers"] || []
    end

    def extent
      self["extent"]
    end

    def carrier
      self["carrier"]
    end

    def media
      self["media"]
    end

    def provision_activity
      self["provision_activity"]
    end

    def edition_statement
      self["edition_statement"]
    end

    def dimensions
      self["dimensions"]
    end

    def publication_statement
      self["publication_statement"]
    end

    def items
      self["items"] || []
    end
  end
end
