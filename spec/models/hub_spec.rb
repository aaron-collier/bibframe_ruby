# frozen_string_literal: true

RSpec.describe BibframeRuby::Hub do
  subject(:hub) do
    described_class.new(
      id: "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac",
      types: ["Work", "Hub", "Series"],
      properties: {
        "title" => title,
        "contributions" => [contribution],
        "language" => "http://id.loc.gov/vocabulary/languages/eng",
        "identifiers" => [],
        "relations" => [],
        "label" => "Dinniman, Matt. Dungeon crawler Carl (Series)"
      }
    )
  end

  let(:title) { BibframeRuby::Title.new(properties: { "main_title" => "Dungeon crawler Carl (Series)" }) }
  let(:contribution) { BibframeRuby::Contribution.new(properties: { "role" => "ctb", "primary" => true }) }

  it "inherits from Resource" do
    expect(hub).to be_a(BibframeRuby::Resource)
  end

  describe "#title" do
    it "returns the Title object" do
      expect(hub.title).to eq(title)
    end
  end

  describe "#contributions" do
    it "returns the contributions array" do
      expect(hub.contributions).to eq([contribution])
    end
  end

  describe "#language" do
    it "returns the language" do
      expect(hub.language).to eq("http://id.loc.gov/vocabulary/languages/eng")
    end
  end

  describe "#identifiers" do
    it "returns the identifiers array" do
      expect(hub.identifiers).to eq([])
    end
  end

  describe "#relations" do
    it "returns the relations array" do
      expect(hub.relations).to eq([])
    end
  end

  describe "#label" do
    it "returns the label" do
      expect(hub.label).to eq("Dinniman, Matt. Dungeon crawler Carl (Series)")
    end
  end
end
