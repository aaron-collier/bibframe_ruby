# frozen_string_literal: true

RSpec.describe BibframeRuby do
  it "has a version number" do
    expect(BibframeRuby::VERSION).not_to be_nil
  end

  describe ".parse" do
    let(:work_jsonld) { File.read(File.join(__dir__, "fixtures/work.jsonld")) }

    it "returns a Graph" do
      result = described_class.parse(work_jsonld, format: :jsonld)
      expect(result).to be_a(BibframeRuby::Graph)
    end

    it "parses works from JSON-LD" do
      result = described_class.parse(work_jsonld, format: :jsonld)
      expect(result.works.length).to eq(1)
    end

    it "defaults format to :jsonld" do
      result = described_class.parse(work_jsonld)
      expect(result.works.length).to eq(1)
    end
  end

  describe ".parse_file" do
    let(:fixture_path) { File.join(__dir__, "fixtures/work.jsonld") }

    it "returns a Graph" do
      result = described_class.parse_file(fixture_path)
      expect(result).to be_a(BibframeRuby::Graph)
    end

    it "detects format from file extension" do
      result = described_class.parse_file(fixture_path)
      expect(result.works.length).to eq(1)
    end
  end
end
