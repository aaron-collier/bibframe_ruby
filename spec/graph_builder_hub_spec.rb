# frozen_string_literal: true

RSpec.describe BibframeRuby::GraphBuilder do
  let(:hub_jsonld) { File.read(File.join(__dir__, "fixtures/hub.jsonld")) }
  let(:rdf_graph) { BibframeRuby::Parser.new(hub_jsonld, format: :jsonld).parse }
  let(:result) { described_class.new(rdf_graph).build }

  describe "Hub parsing" do
    it "returns a hash with hubs array" do
      expect(result[:hubs]).to be_an(Array)
      expect(result[:hubs].length).to be >= 1
    end

    it "creates a Hub instance for bf:Hub typed resources" do
      hub = result[:hubs].first
      expect(hub).to be_a(BibframeRuby::Hub)
    end

    it "does not create a Work for Hub-typed resources" do
      works = result[:works]
      hub_uri = "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac"
      expect(works.map(&:id)).not_to include(hub_uri)
    end

    it "sets the hub id" do
      hub = result[:hubs].find { |h| h.id == "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac" }
      expect(hub).not_to be_nil
    end

    it "populates the hub types" do
      hub = result[:hubs].find { |h| h.id == "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac" }
      expect(hub.types).to include("Hub", "Work", "Series")
    end

    it "populates the hub title as a Title object" do
      hub = result[:hubs].find { |h| h.id == "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac" }
      expect(hub.title).to be_a(BibframeRuby::Title)
      expect(hub.title.main_title).to eq("Dungeon crawler Carl (Series)")
    end

    it "populates hub contributions" do
      hub = result[:hubs].find { |h| h.id == "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac" }
      expect(hub.contributions).to be_an(Array)
      expect(hub.contributions.length).to eq(1)
      expect(hub.contributions.first).to be_a(BibframeRuby::Contribution)
      expect(hub.contributions.first.primary?).to be true
    end

    it "populates hub identifiers" do
      hub = result[:hubs].find { |h| h.id == "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac" }
      expect(hub.identifiers).to be_an(Array)
      expect(hub.identifiers.length).to eq(2)
    end

    it "populates hub relations" do
      hub = result[:hubs].find { |h| h.id == "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac" }
      expect(hub.relations).to be_an(Array)
      expect(hub.relations.length).to eq(1)
    end

    it "hydrates named URI resources like Person from the document" do
      agent = result[:resources].values.find { |r| r.is_a?(BibframeRuby::Person) }
      expect(agent).not_to be_nil
      expect(agent.label).to eq("Dinniman, Matt")
    end
  end
end
