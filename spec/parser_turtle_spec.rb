# frozen_string_literal: true

RSpec.describe BibframeRuby::Parser do
  let(:work_ttl) { File.read(File.join(__dir__, "fixtures/work.ttl")) }

  describe "Turtle parsing" do
    it "returns an RDF::Graph from Turtle input" do
      parser = described_class.new(work_ttl, format: :turtle)
      result = parser.parse
      expect(result).to be_a(RDF::Graph)
    end

    it "parses triples from Turtle input" do
      parser = described_class.new(work_ttl, format: :turtle)
      graph = parser.parse
      expect(graph.count).to be > 0
    end

    it "contains the work subject" do
      parser = described_class.new(work_ttl, format: :turtle)
      graph = parser.parse
      subjects = graph.subjects.map(&:to_s)
      expect(subjects).to include("https://dev.bcld.info/works/c3ab6105-cc37-45ad-b1d0-ca53528f395c")
    end
  end
end

RSpec.describe BibframeRuby do
  describe "Turtle integration" do
    let(:fixture_path) { File.join(__dir__, "fixtures/work.ttl") }

    it "parses a Turtle file via parse_file" do
      result = described_class.parse_file(fixture_path)
      expect(result).to be_a(BibframeRuby::Graph)
      expect(result.works.length).to eq(1)
    end

    it "produces a Work with a title from Turtle" do
      result = described_class.parse_file(fixture_path)
      work = result.works.first
      expect(work.title).to be_a(BibframeRuby::Title)
      expect(work.title.main_title).to eq("Minority voices from the academic superstructure")
    end

    it "produces contributions from Turtle" do
      result = described_class.parse_file(fixture_path)
      work = result.works.first
      expect(work.contributions.length).to eq(3)
      expect(work.contributions.any?(&:primary?)).to be true
    end

    it "populates language from Turtle" do
      result = described_class.parse_file(fixture_path)
      work = result.works.first
      expect(work.language).to eq("http://id.loc.gov/vocabulary/languages/eng")
    end
  end
end
