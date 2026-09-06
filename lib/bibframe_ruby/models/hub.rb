# frozen_string_literal: true

module BibframeRuby
  class Hub < Resource
    def title
      self["title"]
    end

    def contributions
      self["contributions"] || []
    end

    def language
      self["language"]
    end

    def identifiers
      self["identifiers"] || []
    end

    def relations
      self["relations"] || []
    end

    def label
      self["label"]
    end
  end
end
