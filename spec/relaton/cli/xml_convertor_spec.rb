RSpec.describe Relaton::Cli::XMLConvertor do
  describe ".to_yaml" do
    context "with collection xml" do
      it "converts collection xml to relaton yaml" do
        buffer = stub_file_write_to_io(sample_collection_file)
        Relaton::Cli::XMLConvertor.to_yaml(sample_collection_file)

        expect(buffer).to include("id: CC 34000")
        expect(buffer).to include("id: CC/S 34006")
        expect(buffer).to include("title:\n    - content: Date and time -- Calendars")
        expect(buffer).to include("root:\n  title: CalConnect Standards")
      end
    end

    context "with collection and options" do
      it "usages specified options in conversion" do
        stub_file_write_to_io(sample_collection_file)
        buffer = stub_collections_write(collection_names, dir: "./tmp")

        Relaton::Cli::XMLConvertor.to_yaml(
          sample_collection_file, outdir: "./tmp", prefix: "RCLI"
        )

        expect(buffer.count).to eq(6)
        expect(buffer.last).to include("id: CC/S 34006")
        expect(buffer.last).to include("title:\n- content: Date and time -- Calendars")
      end
    end

    context "with a single relaton file" do
      it "converts the relaton xml file to yaml file" do
        buffer = stub_file_write_to_io(sample_relaton_fille)
        Relaton::Cli::XMLConvertor.to_yaml(sample_relaton_fille)

        expect(buffer).to include("id: CC 18001")
        expect(buffer).to include("type: standard")
        expect(buffer).to include("content: standards/csd-datetime-explict")
      end
    end
  end

  describe ".to_html" do
    context "with valid file and styles" do
      it "converts and writes an XML document to HTML" do
        buffer = stub_file_write_to_io(sample_collection_file, "html")

        Relaton::Cli::XMLConvertor.to_html(
          sample_collection_file,
          "spec/assets/index-style.css",
          "spec/assets/templates"
        )

        expect(buffer).to include("I AM A SAMPLE STYLESHEET")
        expect(buffer).to include("Generated: #{Date.today}")
        expect(buffer).to include('<a href="">CC/S 34006</a>')
        expect(buffer).to include("<!DOCTYPE HTML>\n<html>\n  <head>")
        expect(buffer).to include("<title>CalConnect Standards Registry</tit")
      end
    end

    it "ietf to html" do
      file = "spec/fixtures/ietf_index.rxl"
      buffer = stub_file_write_to_io(file, "html")
      Relaton::Cli::XMLConvertor.to_html(file)
      expect(buffer).to include '<a href="spec/fixtures/documents/example.html">1149</a>'
      expect(buffer).to include '<a href="spec/fixtures/documents/example.rxl">Relaton XML</a>'
      expect(buffer).to include '<a href="spec/fixtures/documents/antioch.rfc.xml">draft-camelot-holy-grenade-01</a>'
      expect(buffer).to include '<a href="spec/fixtures/documents/antioch.rxl">Relaton XML</a>'
    end
  end

  def sample_relaton_fille
    @sample_relaton_fille ||= "spec/fixtures/sample.rxl"
  end

  def sample_collection_file
    @sample_collection_file ||= "spec/fixtures/sample-collection.xml"
  end

  def collection_names
    ["cc-34000", "cc-34002", "cc-34003", "cc-34005", "cc-36000", "cc-s-34006"]
  end

  def stub_collections_write(files, dir:, prefix: "RCLI", ext: "rxl")
    files.each.map do |file|
      stub_file_write_to_io([dir, "#{prefix}#{file}.#{ext}"].join("/"))
    end
  end

  def stub_file_write_to_io(file, ext = "yaml")
    buffer = StringIO.new
    out_file = Pathname.new(file).sub_ext(".#{ext}").to_s
    allow(File).to receive(:open).with(out_file, "w:utf-8").and_yield(buffer)

    buffer.string
  end
end
