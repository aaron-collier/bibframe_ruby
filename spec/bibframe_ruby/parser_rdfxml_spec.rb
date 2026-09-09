# frozen_string_literal: true

RSpec.describe BibframeRuby::Parser do
  let(:work_rdf) { read_fixture("work.rdf") }

  describe "RDF/XML parsing" do
    it "returns an RDF::Graph from RDF/XML input" do
      parser = described_class.new(work_rdf, format: :rdfxml)
      result = parser.parse
      expect(result).to be_a(RDF::Graph)
    end

    it "parses triples from RDF/XML input" do
      parser = described_class.new(work_rdf, format: :rdfxml)
      graph = parser.parse
      expect(graph.count).to be > 0
    end

    it "contains the work subject" do
      parser = described_class.new(work_rdf, format: :rdfxml)
      graph = parser.parse
      subjects = graph.subjects.map(&:to_s)
      expect(subjects).to include("http://example.org/test123#Work")
    end
  end
end

RSpec.describe BibframeRuby do
  describe "RDF/XML integration" do
    it "parses an RDF/XML file via parse_file" do
      result = described_class.parse_file(fixture_path("work.rdf"))
      expect(result).to be_a(BibframeRuby::Graph)
      expect(result.works.length).to eq(1)
    end

    it "produces a Work with a title from RDF/XML" do
      result = described_class.parse_file(fixture_path("work.rdf"))
      work = result.works.first
      expect(work.title).to be_a(BibframeRuby::Title)
      expect(work.title.main_title).to eq("Test Title")
    end
  end
end
