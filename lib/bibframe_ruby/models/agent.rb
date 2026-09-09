# frozen_string_literal: true

# BibframeRuby::Agent: A BIBFRAME Agent resource
module BibframeRuby
  # Represents a BIBFRAME Agent — a person, organization, or other entity.
  class Agent < Resource
    def label
      self["label"]
    end
  end
end
