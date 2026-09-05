# frozen_string_literal: true

RSpec.describe BibframeRuby::Contribution do
  subject(:contribution) do
    described_class.new(
      properties: {
        "agent" => agent,
        "role" => "http://id.loc.gov/vocabulary/relators/aut",
        "primary" => true
      }
    )
  end

  let(:agent) { BibframeRuby::Resource.new(id: "http://id.loc.gov/rwo/agents/no2023085548") }

  it "inherits from Resource" do
    expect(contribution).to be_a(BibframeRuby::Resource)
  end

  describe "#agent" do
    it "returns the agent" do
      expect(contribution.agent).to eq(agent)
    end
  end

  describe "#role" do
    it "returns the role URI" do
      expect(contribution.role).to eq("http://id.loc.gov/vocabulary/relators/aut")
    end
  end

  describe "#primary?" do
    it "returns true for primary contributions" do
      expect(contribution.primary?).to be true
    end

    it "returns false when not primary" do
      non_primary = described_class.new(properties: { "primary" => false })
      expect(non_primary.primary?).to be false
    end
  end
end
