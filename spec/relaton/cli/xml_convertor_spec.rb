require "spec_helper"

RSpec.describe Relaton::Cli::XMLConvertor do
  describe ".to_yaml" do
    context "with collection xml" do
      it "converts collection xml to relaton yaml" do
        buffer = stub_file_write_to_io(sample_collection_file)
        Relaton::Cli::XMLConvertor.to_yaml(sample_collection_file)

        expect(buffer).to include("- docidentifier: CC 34000")
        expect(buffer).to include("- docidentifier: CC/S 34006")
        expect(buffer).to include("title: Date and time -- Calendars")
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
        expect(buffer.last).to include("docidentifier: CC/S 34006")
        expect(buffer.last).to include("title: Date and time -- Calendars")
      end
    end
  end

  describe ".to_html" do
    context "with valid file and styles" do
      it "sends render message to xml to html renderer" do
        buffer = stub_file_write_to_io("spec/fixtures/collection.html", "html")

        Relaton::Cli::XMLConvertor.to_html(
          "spec/fixtures/collection.xml",
          "spec/assets/index-style.css",
          "spec/assets/templates",
        )

        expect(buffer).to include("I AM A SAMPLE STYLESHEET")
        expect(buffer).to include("<!DOCTYPE HTML>\n<html>\n  <head>")
        expect(buffer).to include("<title>CalConnect Standards Registry</tit")
        expect(buffer).to include('<a href="csd/cc-r-3101.html">CalConnect ')
      end
    end
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
