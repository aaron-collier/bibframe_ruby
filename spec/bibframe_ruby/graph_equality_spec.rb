# frozen_string_literal: true

RSpec.describe BibframeRuby::Graph do
  describe "#==" do
    let(:graph1) { BibframeRuby.parse_file(fixture_path("work.jsonld")) }

    it "returns true for a graph parsed from the same data" do
      graph2 = BibframeRuby.parse_file(fixture_path("work.jsonld"))
      expect(graph1 == graph2).to be true
    end

    it "returns true after a roundtrip through to_rdf" do
      jsonld = graph1.to_rdf(format: :jsonld)
      graph2 = BibframeRuby.parse(jsonld, format: :jsonld)
      expect(graph1 == graph2).to be true
    end

    it "returns true after a roundtrip through Turtle" do
      ttl = graph1.to_rdf(format: :turtle)
      graph2 = BibframeRuby.parse(ttl, format: :turtle)
      expect(graph1 == graph2).to be true
    end

    it "returns false for a different graph" do
      graph2 = BibframeRuby.parse_file(fixture_path("instance.jsonld"))
      expect(graph1 == graph2).to be false
    end

    it "returns false when compared to a non-Graph object" do
      expect(graph1 == "not a graph").to be false
    end
  end
end
