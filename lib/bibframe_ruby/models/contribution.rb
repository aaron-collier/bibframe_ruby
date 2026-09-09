# frozen_string_literal: true

# BibframeRuby::Contribution: A BIBFRAME Contribution resource
module BibframeRuby
  # Represents a BIBFRAME Contribution — an agent's role in creating a resource.
  class Contribution < Resource
    def agent
      self["agent"]
    end

    def role
      self["role"]
    end

    def primary?
      self["primary"] == true
    end
  end
end
