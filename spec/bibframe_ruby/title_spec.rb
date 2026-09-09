# frozen_string_literal: true

RSpec.describe BibframeRuby::Title do
  subject(:title) do
    described_class.new(
      properties: {
        "main_title" => "The dungeon anarchist's cookbook",
        "subtitle" => "A novel",
        "non_sort_num" => "4"
      }
    )
  end

  it "inherits from Resource" do
    expect(title).to be_a(BibframeRuby::Resource)
  end

  describe "#main_title" do
    it "returns the main title" do
      expect(title.main_title).to eq("The dungeon anarchist's cookbook")
    end
  end

  describe "#subtitle" do
    it "returns the subtitle" do
      expect(title.subtitle).to eq("A novel")
    end
  end

  describe "#non_sort_num" do
    it "returns the non-sort number" do
      expect(title.non_sort_num).to eq("4")
    end
  end
end
