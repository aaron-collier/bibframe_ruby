# frozen_string_literal: true

require_relative "bibframe_ruby/version"
require_relative "bibframe_ruby/resource"
require_relative "bibframe_ruby/models/title"
require_relative "bibframe_ruby/models/work"
require_relative "bibframe_ruby/models/instance"
require_relative "bibframe_ruby/models/item"
require_relative "bibframe_ruby/models/contribution"
require_relative "bibframe_ruby/models/agent"
require_relative "bibframe_ruby/models/person"
require_relative "bibframe_ruby/models/organization"
require_relative "bibframe_ruby/models/subject"
require_relative "bibframe_ruby/parser"
require_relative "bibframe_ruby/graph_builder"

module BibframeRuby
  class Error < StandardError; end
  # Your code goes here...
end
