# frozen_string_literal: true

RSpec.describe BibframeRuby::Parser do
  let(:work_jsonld) { File.read(File.join(__dir__, "fixtures/work.jsonld")) }

  describe "#parse" do
    it "returns an RDF::Graph" do
      parser = described_class.new(work_jsonld, format: :jsonld)
      result = parser.parse
      expect(result).to be_a(RDF::Graph)
    end

    it "parses triples from JSON-LD input" do
      parser = described_class.new(work_jsonld, format: :jsonld)
      graph = parser.parse
      expect(graph.count).to be > 0
    end

    it "contains the work subject" do
      parser = described_class.new(work_jsonld, format: :jsonld)
      graph = parser.parse
      subjects = graph.subjects.map(&:to_s)
      expect(subjects).to include("https://dev.bcld.info/works/25305194-1115-43ab-8a7c-4ef586a1e8e5")
    end
  end

  describe ".format_for_extension" do
    it "returns :jsonld for .jsonld" do
      expect(described_class.format_for_extension(".jsonld")).to eq(:jsonld)
    end

    it "returns :turtle for .ttl" do
      expect(described_class.format_for_extension(".ttl")).to eq(:turtle)
    end

    it "returns :rdfxml for .rdf" do
      expect(described_class.format_for_extension(".rdf")).to eq(:rdfxml)
    end

    it "raises for unknown extensions" do
      expect { described_class.format_for_extension(".xyz") }.to raise_error(BibframeRuby::Error)
    end
  end
end
