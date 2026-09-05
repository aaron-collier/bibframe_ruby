# frozen_string_literal: true

RSpec.describe BibframeRuby::Subject do
  subject(:subj) do
    described_class.new(
      properties: {
        "label" => "Fantasy fiction",
        "source" => "http://id.loc.gov/authorities/subjects"
      }
    )
  end

  it "inherits from Resource" do
    expect(subj).to be_a(BibframeRuby::Resource)
  end

  describe "#label" do
    it "returns the label" do
      expect(subj.label).to eq("Fantasy fiction")
    end
  end

  describe "#source" do
    it "returns the source" do
      expect(subj.source).to eq("http://id.loc.gov/authorities/subjects")
    end
  end
end
