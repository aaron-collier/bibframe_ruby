# frozen_string_literal: true

RSpec.describe BibframeRuby::Agent do
  subject(:agent) do
    described_class.new(
      id: "http://id.loc.gov/rwo/agents/no2023085548",
      properties: { "label" => "Dinniman, Matt" }
    )
  end

  it "inherits from Resource" do
    expect(agent).to be_a(BibframeRuby::Resource)
  end

  describe "#label" do
    it "returns the label" do
      expect(agent.label).to eq("Dinniman, Matt")
    end
  end
end

RSpec.describe BibframeRuby::Person do
  it "inherits from Agent" do
    expect(described_class.new).to be_a(BibframeRuby::Agent)
  end
end

RSpec.describe BibframeRuby::Organization do
  it "inherits from Agent" do
    expect(described_class.new).to be_a(BibframeRuby::Agent)
  end
end
