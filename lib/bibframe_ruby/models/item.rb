# frozen_string_literal: true

# BibframeRuby::Item: A BIBFRAME Item resource
module BibframeRuby
  # Represents a BIBFRAME Item — an individual copy of an Instance.
  class Item < Resource
    def instance
      self["instance"]
    end

    def held_by
      self["held_by"]
    end

    def shelf_mark
      self["shelf_mark"]
    end
  end
end
