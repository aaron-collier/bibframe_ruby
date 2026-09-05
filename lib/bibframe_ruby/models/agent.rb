# frozen_string_literal: true

module BibframeRuby
  class Agent < Resource
    def label
      self["label"]
    end
  end
end
