# frozen_string_literal: true

RSpec.describe BibframeRuby::Item do
  subject(:item) do
    described_class.new(
      id: "http://example.org/items/1",
      types: ["Item"],
      properties: {
        "held_by" => "http://example.org/org/1",
        "shelf_mark" => "PS3604.I49 D85 2024"
      }
    )
  end

  it "inherits from Resource" do
    expect(item).to be_a(BibframeRuby::Resource)
  end

  describe "#instance" do
    it "defaults to nil" do
      expect(item.instance).to be_nil
    end
  end

  describe "#held_by" do
    it "returns the holding organization" do
      expect(item.held_by).to eq("http://example.org/org/1")
    end
  end

  describe "#shelf_mark" do
    it "returns the shelf mark" do
      expect(item.shelf_mark).to eq("PS3604.I49 D85 2024")
    end
  end
end
