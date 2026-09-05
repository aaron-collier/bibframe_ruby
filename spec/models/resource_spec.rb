# frozen_string_literal: true

RSpec.describe BibframeRuby::Resource do
  subject(:resource) do
    described_class.new(
      id: "http://example.org/works/1",
      types: ["Work", "Text"],
      properties: { "title" => "Test Title" }
    )
  end

  describe "#id" do
    it "returns the URI" do
      expect(resource.id).to eq("http://example.org/works/1")
    end
  end

  describe "#types" do
    it "returns the type array" do
      expect(resource.types).to eq(["Work", "Text"])
    end
  end

  describe "#properties" do
    it "returns the properties hash" do
      expect(resource.properties).to eq({ "title" => "Test Title" })
    end
  end

  describe "#[]" do
    it "accesses properties by string key" do
      expect(resource["title"]).to eq("Test Title")
    end

    it "accesses properties by symbol key" do
      expect(resource[:title]).to eq("Test Title")
    end

    it "returns nil for missing keys" do
      expect(resource["missing"]).to be_nil
    end
  end

  describe "#[]=" do
    it "sets properties" do
      resource["language"] = "eng"
      expect(resource["language"]).to eq("eng")
    end
  end
end
