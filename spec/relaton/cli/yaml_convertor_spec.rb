require "spec_helper"

RSpec.describe Relaton::Cli::YAMLConvertor do
  describe ".to_xml" do
    context "with a yaml file" do
      it "converts the yaml content to xml" do
        buffer = stub_file_write_to_io(sample_yaml_file)
        Relaton::Cli::YAMLConvertor.to_xml(sample_yaml_file)

        expect(buffer).to include("<bibdata type='standard'>")
        expect(buffer).to include("<date type=''><on>2018-10-25</on></date>")
        expect(buffer).to include("<technical-committee>PUBLISH</technical-c")
        expect(buffer).to include("<title>Standardization documents -- Vocabu")
      end
    end

    context "with yaml collection" do
      it "converts the collection to xml" do
        buffer = stub_file_write_to_io(sample_collection_file)
        Relaton::Cli::YAMLConvertor.to_xml(sample_collection_file)

        expect(buffer).to include("<date type=''><on>2018-10-25</on></date>")
        expect(buffer).to include("<title>Date and time -- Calendars -- Greg")
        expect(buffer).to include("<title>CalConnect Standards Registry</titl")
        expect(buffer).to include("<relaton-collection xmlns=\"https://open.r")
      end
    end

    context "with yaml and options" do
      it "usages specified extension to write single file" do
        buffer = stub_file_write_to_io(sample_yaml_file, "rxml")

        Relaton::Cli::YAMLConvertor.to_xml(
          sample_yaml_file, outdir: "./tmp", extension: "rxml"
        )

        expect(buffer).to include("<bibdata type='standard'>")
        expect(buffer).to include("<date type=''><on>2018-10-25</on></date>")
        expect(buffer).to include("<technical-committee>PUBLISH</technical-c")
        expect(buffer).to include("<title>Standardization documents -- Vocabu")
      end

      it "usages specified options to write file collection" do
        stub_file_write_to_io(sample_collection_file)
        stub_file_write_to_io("./tmp/RCLIcc-34000.rxl")
        stub_file_write_to_io("./tmp/RCLIcc-34002.rxl")
        stub_file_write_to_io("./tmp/RCLIcc-34003.rxl")
        stub_file_write_to_io("./tmp/RCLIcc-34005.rxl")
        stub_file_write_to_io("./tmp/RCLIcc-36000.rxl")

        buffer = stub_file_write_to_io("./tmp/RCLIcc-s-34006.rxl")

        Relaton::Cli::YAMLConvertor.to_xml(
          sample_collection_file, prefix: "RCLI", outdir: "./tmp"
        )

        expect(buffer).to include("<bibdata type='specification'>")
        expect(buffer).to include("<docidentifier>CC/S 34006</docidentifier>")
      end
    end
  end

  def sample_yaml_file
    @sample_yaml_file ||= "spec/fixtures/sample.yaml"
  end

  def sample_collection_file
    @sample_collection_file ||= "spec/fixtures/sample-collection.yaml"
  end

  def stub_yaml_file_load(file)
    allow(YAML).to receive(:load_file).and_return(YAML.load_file(file))
  end

  def stub_collection_write
    stub_file_write_to_io(sample_collection_file)
    stub_file_write_to_io("./tmp/RCLIcc-34000.rxl")
    stub_file_write_to_io("./tmp/RCLIcc-34002.rxl")
    stub_file_write_to_io("./tmp/RCLIcc-34003.rxl")
    stub_file_write_to_io("./tmp/RCLIcc-34005.rxl")
    stub_file_write_to_io("./tmp/RCLIcc-36000.rxl")

    stub_file_write_to_io("./tmp/RCLIcc-s-34006.rxl")
  end

  def stub_file_write_to_io(file, ext = "rxl")
    buffer = StringIO.new
    out_file = Pathname.new(file).sub_ext(".#{ext}").to_s

    stub_yaml_file_load(file) if file.include?(".yaml")
    allow(File).to receive(:open).with(out_file, "w:utf-8").and_yield(buffer)

    buffer.string
  end
end
