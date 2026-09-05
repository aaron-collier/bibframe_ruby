# frozen_string_literal: true

RSpec.describe BibframeRuby::GraphBuilder do
  let(:work_jsonld) { File.read(File.join(__dir__, "fixtures/work.jsonld")) }
  let(:rdf_graph) { BibframeRuby::Parser.new(work_jsonld, format: :jsonld).parse }
  let(:result) { described_class.new(rdf_graph).build }

  describe "#build" do
    it "returns a hash with resources" do
      expect(result).to have_key(:resources)
      expect(result[:resources]).to be_a(Hash)
    end

    it "returns a hash with works array" do
      expect(result[:works]).to be_an(Array)
      expect(result[:works].length).to eq(1)
    end

    it "creates a Work instance for bf:Work typed resources" do
      work = result[:works].first
      expect(work).to be_a(BibframeRuby::Work)
    end

    it "sets the work id" do
      work = result[:works].first
      expect(work.id).to eq("https://dev.bcld.info/works/25305194-1115-43ab-8a7c-4ef586a1e8e5")
    end

    it "populates the work types" do
      work = result[:works].first
      expect(work.types).to include("Work", "Text", "Monograph")
    end

    it "populates the work title as a Title object" do
      work = result[:works].first
      expect(work.title).to be_a(BibframeRuby::Title)
      expect(work.title.main_title).to eq("The dungeon anarchist's cookbook")
    end

    it "populates the title non_sort_num" do
      work = result[:works].first
      expect(work.title.non_sort_num).to eq("4")
    end

    it "populates the work language" do
      work = result[:works].first
      expect(work.language).to eq("http://id.loc.gov/vocabulary/languages/eng")
    end

    it "populates genre_forms as URI strings" do
      work = result[:works].first
      expect(work.genre_forms).to include("http://id.loc.gov/authorities/genreForms/gf2014026339")
      expect(work.genre_forms.length).to eq(3)
    end

    it "populates the work summary" do
      work = result[:works].first
      expect(work.summary).to be_a(String)
      expect(work.summary).to include("Welcome to the Gun Show!")
    end

    it "populates contributions" do
      work = result[:works].first
      expect(work.contributions).to be_an(Array)
      expect(work.contributions.length).to eq(1)
    end

    it "creates Contribution objects with agent and role" do
      contribution = result[:works].first.contributions.first
      expect(contribution).to be_a(BibframeRuby::Contribution)
      expect(contribution.role).to eq("http://id.loc.gov/vocabulary/relators/aut")
    end

    it "marks primary contributions" do
      contribution = result[:works].first.contributions.first
      expect(contribution.primary?).to be true
    end

    it "creates a stub Resource for the agent URI" do
      agent = result[:works].first.contributions.first.agent
      expect(agent).to be_a(BibframeRuby::Resource)
      expect(agent.id).to eq("http://id.loc.gov/rwo/agents/no2023085548")
    end

    it "creates stub resources for hasInstance URIs" do
      work = result[:works].first
      expect(work.instances).to be_an(Array)
      expect(work.instances.length).to eq(1)
      expect(work.instances.first.id).to eq("https://dev.bcld.info/instances/4e0a7e08-b92a-46e5-8827-bdb635fef24a")
    end

    it "populates classifications" do
      work = result[:works].first
      expect(work.classifications).to be_an(Array)
      expect(work.classifications.length).to eq(2)
    end
  end

  context "with combined work and instance data" do
    let(:instance_jsonld) { File.read(File.join(__dir__, "fixtures/instance.jsonld")) }
    let(:combined_graph) do
      graph = rdf_graph
      BibframeRuby::Parser.new(instance_jsonld, format: :jsonld).parse.each_statement { |s| graph << s }
      graph
    end
    let(:combined_result) { described_class.new(combined_graph).build }

    it "creates both Work and Instance objects" do
      expect(combined_result[:works].length).to eq(1)
      expect(combined_result[:instances].length).to eq(1)
    end

    it "links work.instances to the hydrated Instance" do
      work = combined_result[:works].first
      instance = combined_result[:instances].first
      expect(work.instances.first).to eq(instance)
    end

    it "links instance.work to the hydrated Work" do
      work = combined_result[:works].first
      instance = combined_result[:instances].first
      expect(instance.work).to eq(work)
    end

    it "populates instance title" do
      instance = combined_result[:instances].first
      expect(instance.title).to be_a(BibframeRuby::Title)
      expect(instance.title.main_title).to eq("The dungeon anarchist's cookbook")
    end

    it "populates instance identifiers" do
      instance = combined_result[:instances].first
      expect(instance.identifiers).to be_an(Array)
      expect(instance.identifiers.length).to eq(2)
    end

    it "populates instance extent" do
      instance = combined_result[:instances].first
      expect(instance.extent).to eq("532 pages")
    end

    it "populates instance dimensions" do
      instance = combined_result[:instances].first
      expect(instance.dimensions).to eq("24 cm")
    end

    it "populates instance edition_statement" do
      instance = combined_result[:instances].first
      expect(instance.edition_statement).to eq("First Ace edition")
    end

    it "populates instance publication_statement" do
      instance = combined_result[:instances].first
      expect(instance.publication_statement).to eq("New York: Ace, 2024")
    end
  end
end
