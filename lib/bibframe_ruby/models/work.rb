# frozen_string_literal: true

# BibframeRuby::Work: A BIBFRAME Work resource
module BibframeRuby
  # Represents a BIBFRAME Work — the intellectual content of a bibliographic resource.
  class Work < Resource
    def title
      self["title"]
    end

    def contributions
      self["contributions"] || []
    end

    def instances
      self["instances"] || []
    end

    def language
      self["language"]
    end

    def subjects
      self["subjects"] || []
    end

    def genre_forms
      self["genre_forms"] || []
    end

    def summary
      self["summary"]
    end

    def classifications
      self["classifications"] || []
    end

    def relations
      self["relations"] || []
    end

    def aap
      self["aap"]
    end
  end
end
