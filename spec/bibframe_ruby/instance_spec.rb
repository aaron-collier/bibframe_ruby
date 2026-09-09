# frozen_string_literal: true

RSpec.describe BibframeRuby::Instance do
  subject(:instance) do
    described_class.new(
      id: "http://example.org/instances/1",
      types: ["Instance"],
      properties: {
        "title" => title,
        "extent" => "532 pages",
        "dimensions" => "24 cm",
        "edition_statement" => "First Ace edition",
        "publication_statement" => "New York: Ace, 2024",
        "identifiers" => [],
        "carrier" => "http://id.loc.gov/vocabulary/carriers/nc",
        "media" => "http://id.loc.gov/vocabulary/mediaTypes/n"
      }
    )
  end

  let(:title) { BibframeRuby::Title.new(properties: { "main_title" => "Test" }) }

  it "inherits from Resource" do
    expect(instance).to be_a(BibframeRuby::Resource)
  end

  describe "#title" do
    it "returns the Title" do
      expect(instance.title).to eq(title)
    end
  end

  describe "#work" do
    it "defaults to nil" do
      expect(instance.work).to be_nil
    end
  end

  describe "#extent" do
    it "returns the extent" do
      expect(instance.extent).to eq("532 pages")
    end
  end

  describe "#dimensions" do
    it "returns the dimensions" do
      expect(instance.dimensions).to eq("24 cm")
    end
  end

  describe "#edition_statement" do
    it "returns the edition statement" do
      expect(instance.edition_statement).to eq("First Ace edition")
    end
  end

  describe "#publication_statement" do
    it "returns the publication statement" do
      expect(instance.publication_statement).to eq("New York: Ace, 2024")
    end
  end

  describe "#items" do
    it "defaults to empty array" do
      expect(instance.items).to eq([])
    end
  end

  describe "#identifiers" do
    it "returns the identifiers array" do
      expect(instance.identifiers).to eq([])
    end
  end
end
