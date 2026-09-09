# frozen_string_literal: true

RSpec.describe BibframeRuby do
  describe ".convert_marc" do
    let(:marc_path) { fixture_path("record.mrc") }

    it "returns a Graph" do
      result = described_class.convert_marc(marc_path)
      expect(result).to be_a(BibframeRuby::Graph)
    end

    it "produces Works from MARC" do
      result = described_class.convert_marc(marc_path)
      expect(result.works.length).to eq(1)
    end

    it "produces Instances from MARC" do
      result = described_class.convert_marc(marc_path)
      expect(result.instances.length).to eq(1)
    end

    it "populates the Work title" do
      result = described_class.convert_marc(marc_path)
      work = result.works.first
      expect(work.title).to be_a(BibframeRuby::Title)
      expect(work.title.main_title).to eq("Fixture MARC Record")
    end

    it "passes baseuri through to the transform" do
      result = described_class.convert_marc(marc_path, baseuri: "http://mylib.org/")
      work = result.works.first
      expect(work.id).to start_with("http://mylib.org/")
    end

    it "populates the Work language" do
      result = described_class.convert_marc(marc_path)
      work = result.works.first
      expect(work.language).to eq("http://id.loc.gov/vocabulary/languages/eng")
    end
  end
end
