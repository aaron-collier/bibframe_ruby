# frozen_string_literal: true

require "marc"

RSpec.describe BibframeRuby::MarcConverter do
  let(:marcxml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <collection xmlns="http://www.loc.gov/MARC21/slim">
        <record>
          <leader>00000nam a2200000 a 4500</leader>
          <controlfield tag="001">conv123</controlfield>
          <controlfield tag="008">240101s2024    nyu           000 0 eng d</controlfield>
          <datafield tag="245" ind1="1" ind2="0">
            <subfield code="a">MARC Conversion Test</subfield>
          </datafield>
        </record>
      </collection>
    XML
  end

  let(:binary_marc) do
    record = MARC::Record.new
    record.leader = "00000nam a2200000 a 4500"
    record.append(MARC::ControlField.new("001", "conv456"))
    record.append(MARC::ControlField.new("008", "240101s2024    nyu           000 0 eng d"))
    record.append(MARC::DataField.new("245", "1", "0", ["a", "Binary MARC Test"]))
    writer = StringIO.new
    marc_writer = MARC::Writer.new(writer)
    marc_writer.write(record)
    marc_writer.close
    writer.string
  end

  describe "#convert" do
    it "converts MARCXML to RDF/XML" do
      converter = described_class.new(marcxml, baseuri: "http://example.org/", idsource: "test")
      result = converter.convert
      expect(result).to include("rdf:RDF")
      expect(result).to include("bf:Work")
      expect(result).to include("MARC Conversion Test")
    end

    it "converts binary MARC to RDF/XML" do
      converter = described_class.new(binary_marc, baseuri: "http://example.org/", idsource: "test")
      result = converter.convert
      expect(result).to include("rdf:RDF")
      expect(result).to include("bf:Work")
      expect(result).to include("Binary MARC Test")
    end

    it "passes baseuri to the XSLT" do
      converter = described_class.new(marcxml, baseuri: "http://mylib.org/catalog/", idsource: "test")
      result = converter.convert
      expect(result).to include("http://mylib.org/catalog/")
    end

    it "uses default baseuri when none provided" do
      converter = described_class.new(marcxml, idsource: "test")
      result = converter.convert
      expect(result).to include("http://example.org/")
    end
  end

  describe ".marcxml?" do
    it "returns true for XML content" do
      expect(described_class.marcxml?(marcxml)).to be true
    end

    it "returns false for binary MARC content" do
      expect(described_class.marcxml?(binary_marc)).to be false
    end
  end
end
