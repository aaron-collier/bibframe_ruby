# frozen_string_literal: true

RSpec.describe BibframeRuby::Graph do
  let(:graph) { BibframeRuby.parse_file(fixture_path("work.jsonld")) }

  describe "#to_rdf" do
    context "with JSON-LD format (default)" do
      it "returns a string" do
        result = graph.to_rdf
        expect(result).to be_a(String)
      end

      it "returns valid JSON-LD" do
        result = graph.to_rdf
        parsed = JSON.parse(result)
        expect(parsed).to be_a(Hash).or be_a(Array)
      end

      it "includes the work URI" do
        result = graph.to_rdf
        expect(result).to include("https://dev.bcld.info/works/25305194-1115-43ab-8a7c-4ef586a1e8e5")
      end

      it "includes BIBFRAME type" do
        result = graph.to_rdf
        expect(result).to include("bf:Work")
      end
    end

    context "with Turtle format" do
      it "returns a string" do
        result = graph.to_rdf(format: :turtle)
        expect(result).to be_a(String)
      end

      it "includes Turtle prefix declarations" do
        result = graph.to_rdf(format: :turtle)
        expect(result).to include("@prefix")
      end

      it "includes the work URI" do
        result = graph.to_rdf(format: :turtle)
        expect(result).to include("https://dev.bcld.info/works/25305194-1115-43ab-8a7c-4ef586a1e8e5")
      end
    end

    it "raises for unsupported formats" do
      expect { graph.to_rdf(format: :nquads) }.to raise_error(BibframeRuby::Error, /Unsupported/)
    end
  end
end

RSpec.describe BibframeRuby::Resource do
  let(:graph) { BibframeRuby.parse_file(fixture_path("work.jsonld")) }
  let(:work) { graph.works.first }

  describe "#to_rdf" do
    context "with JSON-LD format (default)" do
      it "returns a string" do
        result = work.to_rdf
        expect(result).to be_a(String)
      end

      it "includes the resource URI" do
        result = work.to_rdf
        expect(result).to include("https://dev.bcld.info/works/25305194-1115-43ab-8a7c-4ef586a1e8e5")
      end

      it "includes the title" do
        result = work.to_rdf
        expect(result).to include("dungeon anarchist")
      end
    end

    context "with Turtle format" do
      it "returns Turtle output" do
        result = work.to_rdf(format: :turtle)
        expect(result).to include("@prefix")
        expect(result).to include("https://dev.bcld.info/works/25305194-1115-43ab-8a7c-4ef586a1e8e5")
      end
    end

    it "raises for unsupported formats" do
      expect { work.to_rdf(format: :nquads) }.to raise_error(BibframeRuby::Error, /Unsupported/)
    end
  end
end
