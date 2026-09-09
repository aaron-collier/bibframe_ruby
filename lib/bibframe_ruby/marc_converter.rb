# frozen_string_literal: true

# BibframeRuby::MarcConverter: Converts MARC records to BIBFRAME RDF/XML via XSLT

require "nokogiri"
require "marc"
require "stringio"

module BibframeRuby
  # Converts MARC (binary or MARCXML) to BIBFRAME RDF/XML using the vendored marc2bibframe2 XSLT.
  class MarcConverter
    XSL_DIR = File.expand_path("../../vendor/marc2bibframe2/xsl", __dir__)
    XSL_PATH = File.join(XSL_DIR, "marc2bibframe2.xsl")

    def initialize(input, baseuri: "http://example.org/", idsource: nil)
      @input = input
      @baseuri = baseuri
      @idsource = idsource
    end

    def convert
      xml = self.class.marcxml?(@input) ? @input : binary_to_marcxml(@input)
      doc = Nokogiri::XML(xml)
      rdfxml = transform(doc)
      rdfxml.to_xml
    end

    def self.marcxml?(input)
      input.lstrip.start_with?("<")
    end

    private

    def binary_to_marcxml(input)
      reader = MARC::Reader.new(StringIO.new(input))
      output = StringIO.new
      writer = MARC::XMLWriter.new(output)
      reader.each { |record| writer.write(record) }
      writer.close
      output.string
    end

    def transform(doc)
      params = ["baseuri", "\"#{@baseuri}\""]
      params += ["idsource", "\"#{@idsource}\""] if @idsource

      Dir.chdir(XSL_DIR) do
        self.class.stylesheet.transform(doc, params)
      end
    end

    def self.stylesheet
      @stylesheet ||= Dir.chdir(XSL_DIR) do
        Nokogiri::XSLT(File.read(XSL_PATH))
      end
    end
  end
end
