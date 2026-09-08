# frozen_string_literal: true

RSpec.describe BibframeRuby::Work do
  subject(:work) do
    described_class.new(
      id: "http://example.org/works/1",
      types: %w[Work Text],
      properties: {
        "title" => title,
        "language" => "http://id.loc.gov/vocabulary/languages/eng",
        "summary" => "A test summary",
        "contributions" => [contribution],
        "genre_forms" => ["http://id.loc.gov/authorities/genreForms/gf2014026339"],
        "classifications" => [],
        "relations" => []
      }
    )
  end

  let(:title) { BibframeRuby::Title.new(properties: { "main_title" => "Test Work" }) }
  let(:contribution) { BibframeRuby::Contribution.new(properties: { "role" => "aut", "primary" => true }) }

  it "inherits from Resource" do
    expect(work).to be_a(BibframeRuby::Resource)
  end

  describe "#title" do
    it "returns the Title object" do
      expect(work.title).to eq(title)
    end
  end

  describe "#contributions" do
    it "returns the contributions array" do
      expect(work.contributions).to eq([contribution])
    end
  end

  describe "#instances" do
    it "defaults to empty array" do
      expect(work.instances).to eq([])
    end
  end

  describe "#language" do
    it "returns the language" do
      expect(work.language).to eq("http://id.loc.gov/vocabulary/languages/eng")
    end
  end

  describe "#summary" do
    it "returns the summary" do
      expect(work.summary).to eq("A test summary")
    end
  end

  describe "#genre_forms" do
    it "returns the genre forms array" do
      expect(work.genre_forms).to eq(["http://id.loc.gov/authorities/genreForms/gf2014026339"])
    end
  end

  describe "#subjects" do
    it "defaults to empty array" do
      expect(work.subjects).to eq([])
    end
  end
end
