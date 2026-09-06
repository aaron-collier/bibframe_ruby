# frozen_string_literal: true

require "net/http"
require "uri"
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
require_relative "bibframe_ruby/models/hub"
require_relative "bibframe_ruby/parser"
require_relative "bibframe_ruby/graph_builder"
require_relative "bibframe_ruby/graph"

module BibframeRuby
  class Error < StandardError; end

  def self.parse(input, format: :jsonld)
    rdf_graph = Parser.new(input, format: format).parse
    Graph.from_rdf(rdf_graph)
  end

  def self.parse_file(path)
    ext = File.extname(path)
    format = Parser.format_for_extension(ext)
    input = File.read(path)
    parse(input, format: format)
  end

  def self.parse_uri(uri, redirect_limit: 5)
    raise Error, "Too many redirects" if redirect_limit == 0

    parsed_uri = URI.parse(uri)
    response = Net::HTTP.get_response(parsed_uri)

    if response.is_a?(Net::HTTPSuccess)
      ext = File.extname(parsed_uri.path)
      format = ext.empty? ? :jsonld : Parser.format_for_extension(ext)
      parse(response.body, format: format)
    elsif response.is_a?(Net::HTTPRedirection)
      parse_uri(response["location"], redirect_limit: redirect_limit - 1)
    else
      raise Error, "HTTP error: #{response.code} #{response.message}"
    end
  end
end
