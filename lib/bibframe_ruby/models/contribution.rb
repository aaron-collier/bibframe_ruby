# frozen_string_literal: true

module BibframeRuby
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
