require "spec_helper"

RSpec.describe Relaton::Cli::YAMLConvertorNew do
  describe ".to_xml" do
    context "with a yaml file" do
      it "converts the yaml content to xml" do
        buffer = stub_file_write_to_io(sample_yaml_file)
        Relaton::Cli::YAMLConvertorNew.to_xml(sample_yaml_file)
        expect(buffer).to be_equivalent_to <<~"OUTPUT"
          <bibdata type="standard">
            <fetched>#{Date.today}</fetched>
            <title type="main" format="text/plain">Standardization documents -- Vocabulary</title>
            <docidentifier type="CC">CC 36000</docidentifier>
            <date type="issued">
              <on>2018-10-25</on>
            </date>
            <status>
              <stage>proposal</stage>
            </status>
          </bibdata>
        OUTPUT
      end
    end

    context "with yaml collection" do
      it "converts the collection to xml" do
        buffer = stub_file_write_to_io(sample_collection_file)
        Relaton::Cli::YAMLConvertorNew.to_xml(sample_collection_file)

        expect(buffer).to match(%r(<date type="issued">\s*<on>2018-10-25</on>\s*</date>))
        expect(buffer).to include(%(<title type="main" format="text/plain">Date and time -- Calendars -- Greg))
        expect(buffer).to include("<title>CalConnect Standards Registry</titl")
        expect(buffer).to include("<relaton-collection xmlns=\"https://open.r")
      end
    end

    context "with yaml and options" do
      it "usages options extension to write single file" do
        buffer = stub_file_write_to_io(sample_yaml_file, "rxml")

        Relaton::Cli::YAMLConvertorNew.to_xml(
          sample_yaml_file, outdir: "./tmp", extension: "rxml"
        )

        expect(buffer).to be_equivalent_to <<~"OUTPUT"
          <bibdata type="standard">
            <fetched>#{Date.today}</fetched>
            <title type="main" format="text/plain">Standardization documents -- Vocabulary</title>
            <docidentifier type="CC">CC 36000</docidentifier>
            <date type="issued">
              <on>2018-10-25</on>
            </date>
            <status>
              <stage>proposal</stage>
            </status>
          </bibdata>
        OUTPUT
      end

      it "uses specified options to write file collection" do
        stub_file_write_to_io(sample_collection_file)
        buffer = stub_collections_write(collection_names, dir: "./tmp")

        Relaton::Cli::YAMLConvertorNew.to_xml(
          sample_collection_file, prefix: "RCLI", outdir: "./tmp"
        )

        expect(buffer.count).to eq(6)
        expect(buffer.last).to be_equivalent_to <<~"OUTPUT"
          <bibdata type="standard">
            <fetched>#{Date.today}</fetched>
            <title type="main" format="text/plain">Date and time -- Calendars -- Chinese calendar</title>
            <docidentifier type="CC">CC/S 34006</docidentifier>
            <date type="issued">
              <on>2018-10-25</on>
            </date>
            <status>
              <stage>proposal</stage>
            </status>
          </bibdata>
        OUTPUT
      end

      it "don't write" do
        xml = Relaton::Cli::YAMLConvertorNew.to_xml(sample_yaml_file, write: false)
        expect(xml).to be_equivalent_to <<~OUTPUT
          <bibdata type="standard">
            <fetched>#{Date.today}</fetched>
            <title type="main" format="text/plain">Standardization documents -- Vocabulary</title>
            <docidentifier type="CC">CC 36000</docidentifier>
            <date type="issued">
              <on>2018-10-25</on>
            </date>
            <status>
              <stage>proposal</stage>
            </status>
          </bibdata>
        OUTPUT
      end
    end

    context "document type" do
      it "ISO" do
        xml = Relaton::Cli::YAMLConvertorNew.to_xml(
          "spec/fixturesnew/sample_iso.yaml", write: false
        )
        expect(xml).to be_equivalent_to File.read(
          "spec/fixturesnew/sample_iso.xml", encoding: "UTF-8"
        ).sub %r{(?<=<fetched>)\d{4}-\d{2}-\d{2}}, Date.today.to_s
      end
    end
  end

  describe ".to_html" do
    context "with valid file and styles" do
      it "converts and writes a YAML document to HTML" do
        buffer = stub_file_write_to_io(sample_collection_file, "html")

        Relaton::Cli::YAMLConvertorNew.to_html(
          sample_collection_file,
          "spec/assets/index-style.css",
          "spec/assets/templates",
        )

        expect(buffer).to include("I AM A SAMPLE STYLESHEET")
        expect(buffer).to include('<a href="">CC/S 34006</a>')
        expect(buffer).to include("<!DOCTYPE HTML>\n<html>\n  <head>")
        expect(buffer).to include("<title>CalConnect Standards Registry</tit")
      end
    end
  end

  def sample_yaml_file
    @sample_yaml_file ||= "spec/fixturesnew/samplenew.yaml"
  end

  def sample_collection_file
    @sample_collection_file ||= "spec/fixturesnew/sample-collectionnew.yaml"
  end

  def stub_yaml_file_load(file)
    allow(YAML).to receive(:load_file).and_return(YAML.load_file(file))
  end

  def collection_names
    ["cc-34000", "cc-34002", "cc-34003", "cc-34005", "cc-36000", "cc-s-34006"]
  end

  def stub_collections_write(files, dir:, prefix: "RCLI", ext: "yaml")
    files.each.map do |file|
      stub_file_write_to_io([dir, "#{prefix}#{file}.#{ext}"].join("/"))
    end
  end

  def stub_file_write_to_io(file, ext = "rxl")
    buffer = StringIO.new
    stub_yaml_file_load(file) if file.include?(".yaml")

    out_file = Pathname.new(file).sub_ext(".#{ext}").to_s
    allow(File).to receive(:open).with(out_file, "w:utf-8").and_yield(buffer)

    buffer.string
  end
end
