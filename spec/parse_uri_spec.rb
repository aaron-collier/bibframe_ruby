# frozen_string_literal: true

require "net/http"

RSpec.describe BibframeRuby do
  describe ".parse_uri" do
    let(:hub_jsonld) { File.read(File.join(__dir__, "fixtures/hub.jsonld")) }
    let(:hub_uri) { "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac.jsonld" }

    before do
      stub_response = instance_double(Net::HTTPOK, body: hub_jsonld, is_a?: true)
      allow(stub_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(Net::HTTP).to receive(:get_response).and_return(stub_response)
    end

    it "returns a Graph" do
      result = described_class.parse_uri(hub_uri)
      expect(result).to be_a(BibframeRuby::Graph)
    end

    it "parses resources from the fetched content" do
      result = described_class.parse_uri(hub_uri)
      expect(result.hubs.length).to be >= 1
    end

    it "detects format from the URI extension" do
      result = described_class.parse_uri(hub_uri)
      hub = result.hubs.find { |h| h.id == "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac" }
      expect(hub).not_to be_nil
      expect(hub.title.main_title).to eq("Dungeon crawler Carl (Series)")
    end

    it "raises on HTTP errors" do
      error_response = instance_double(Net::HTTPNotFound, code: "404", message: "Not Found")
      allow(error_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(error_response).to receive(:is_a?).with(Net::HTTPRedirection).and_return(false)
      allow(Net::HTTP).to receive(:get_response).and_return(error_response)

      expect { described_class.parse_uri(hub_uri) }.to raise_error(BibframeRuby::Error, /HTTP error: 404/)
    end

    it "follows HTTP redirects" do
      redirect_uri = "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac"
      final_uri = "https://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac.jsonld"

      redirect_response = instance_double(Net::HTTPMovedPermanently)
      allow(redirect_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(redirect_response).to receive(:is_a?).with(Net::HTTPRedirection).and_return(true)
      allow(redirect_response).to receive(:[]).with("location").and_return(final_uri)

      success_response = instance_double(Net::HTTPOK, body: hub_jsonld)
      allow(success_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      allow(Net::HTTP).to receive(:get_response).with(URI.parse(redirect_uri)).and_return(redirect_response)
      allow(Net::HTTP).to receive(:get_response).with(URI.parse(final_uri)).and_return(success_response)

      result = BibframeRuby.parse_uri(redirect_uri)
      expect(result).to be_a(BibframeRuby::Graph)
      expect(result.hubs.length).to be >= 1
    end

    it "raises on too many redirects" do
      redirect_response = instance_double(Net::HTTPMovedPermanently)
      allow(redirect_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(redirect_response).to receive(:is_a?).with(Net::HTTPRedirection).and_return(true)
      allow(redirect_response).to receive(:[]).with("location").and_return(hub_uri)
      allow(Net::HTTP).to receive(:get_response).and_return(redirect_response)

      expect do
        BibframeRuby.parse_uri(hub_uri, redirect_limit: 0)
      end.to raise_error(BibframeRuby::Error, /Too many redirects/)
    end

    it "defaults to jsonld format when URI has no extension" do
      no_ext_uri = "http://id.loc.gov/resources/hubs/4076e139-793f-bb85-515c-840510066bac"
      result = described_class.parse_uri(no_ext_uri)
      expect(result).to be_a(BibframeRuby::Graph)
    end
  end
end
