# frozen_string_literal: true

RSpec.describe BibframeRuby::Graph do
  let(:work_jsonld) { read_fixture("work.jsonld") }
  let(:instance_jsonld) { read_fixture("instance.jsonld") }

  describe ".from_rdf" do
    it "creates a Graph from an RDF::Graph" do
      rdf_graph = BibframeRuby::Parser.new(work_jsonld, format: :jsonld).parse
      graph = described_class.from_rdf(rdf_graph)
      expect(graph).to be_a(described_class)
    end
  end

  describe "#works" do
    it "returns Work objects" do
      rdf_graph = BibframeRuby::Parser.new(work_jsonld, format: :jsonld).parse
      graph = described_class.from_rdf(rdf_graph)
      expect(graph.works).to be_an(Array)
      expect(graph.works.first).to be_a(BibframeRuby::Work)
    end
  end

  describe "#instances" do
    it "returns Instance objects" do
      rdf_graph = BibframeRuby::Parser.new(instance_jsonld, format: :jsonld).parse
      graph = described_class.from_rdf(rdf_graph)
      expect(graph.instances).to be_an(Array)
      expect(graph.instances.first).to be_a(BibframeRuby::Instance)
    end
  end

  describe "#resources" do
    it "returns all resources" do
      rdf_graph = BibframeRuby::Parser.new(work_jsonld, format: :jsonld).parse
      graph = described_class.from_rdf(rdf_graph)
      expect(graph.resources).to be_an(Array)
      expect(graph.resources.length).to be > 1
    end
  end
end
