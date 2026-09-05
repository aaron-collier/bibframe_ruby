# frozen_string_literal: true

module BibframeRuby
  class Title < Resource
    def main_title
      self["main_title"]
    end

    def subtitle
      self["subtitle"]
    end

    def non_sort_num
      self["non_sort_num"]
    end
  end
end
