# frozen_string_literal: true

# BibframeRuby::Title: A BIBFRAME Title resource
module BibframeRuby
  # Represents a BIBFRAME Title with main title, subtitle, and non-sort number.
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
