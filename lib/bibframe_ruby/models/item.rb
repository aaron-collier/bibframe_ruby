# frozen_string_literal: true

module BibframeRuby
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
