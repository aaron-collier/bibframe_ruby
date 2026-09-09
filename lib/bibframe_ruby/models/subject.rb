# frozen_string_literal: true

# BibframeRuby::Subject: A BIBFRAME Subject resource
module BibframeRuby
  # Represents a BIBFRAME Subject — a topic or concept associated with a resource.
  class Subject < Resource
    def label
      self["label"]
    end

    def source
      self["source"]
    end
  end
end
