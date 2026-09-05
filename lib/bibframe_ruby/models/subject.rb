# frozen_string_literal: true

module BibframeRuby
  class Subject < Resource
    def label
      self["label"]
    end

    def source
      self["source"]
    end
  end
end
