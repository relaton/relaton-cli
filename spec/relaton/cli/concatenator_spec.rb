require "fileutils"
require "spec_helper"

RSpec.describe Relaton::Cli::Concatenator do
  describe ".concatenate" do
    context "with YAML & RXL files in source directory" do
      it "combines both type of files into a collection" do
        Relaton::Cli::Concatenator.concatenate(
          "spec/fixtures", "./tmp/concatenate.rxl"
        )

        xml = File.read("./tmp/concatenate.rxl")
        xmldoc = Nokogiri::XML(xml)

        expect(xmldoc.root.at("./xmlns:title")).to be_nil
        expect(xmldoc.root.at("./xmlns:contributor")).to be_nil

        expect(xml).to include("<docidentifier>CC 18001</docidentifier>")
        expect(xml).to include("<docidentifier>CC 36000</docidentifier>")
        expect(xml).not_to include("'xml'>spec/fixtures/sample-collection")
      end
    end

    context "with YAML, RXL files and custom options" do
      it "combines both type of files and usages the options" do
        Relaton::Cli::Concatenator.concatenate(
          "spec/fixtures",
          "./tmp/concatenate.rxl",
          title: "collection title",
          organization: "Ribose Inc",
        )

        xml = File.read("./tmp/concatenate.rxl")
        xmldoc = Nokogiri::XML(xml)

        doc_title = xmldoc.root.at("./xmlns:title").text
        doc_contributor = xmldoc.root.at(
          "./xmlns:contributor/xmlns:organization/xmlns:name",
        ).text

        expect(doc_title).to eq("collection title")
        expect(doc_contributor).to eq("Ribose Inc")
        expect(xml).to include("<docidentifier>CC 36000</docidentifier>")
      end
    end

    context "with YAML, RXL and linked documents" do
      it "combines documents and also add dynamic links" do
        file_types = ["xml", "pdf", "doc", "html"]
        create_fixture_files("sample", file_types)

        Relaton::Cli::Concatenator.concatenate(
          "spec/fixtures", "./tmp/concatenate.rxl"
        )

        cleanup_fixture_files("sample", file_types)
        xml = File.read("./tmp/concatenate.rxl")
        xmldoc = Nokogiri::XML(xml)

        expect(xmldoc.root.at("./xmlns:title")).to be_nil
        expect(xmldoc.root.at("./xmlns:contributor")).to be_nil

        expect(xml).to include("<docidentifier>CC 18001</docidentifier>")
        expect(xml).to include("<uri type='xml'>spec/fixtures/sample.xml")
        expect(xml).to include("<uri type='pdf'>spec/fixtures/sample.pdf")
        expect(xml).to include("<uri type='doc'>spec/fixtures/sample.doc")
        expect(xml).to include("<uri type='html'>spec/fixtures/sample.html")
      end
    end
  end

  def cleanup_fixture_files(name, types = [])
    types.each { |type| FileUtils.rm("spec/fixtures/#{name}.#{type}") }
  end

  def create_fixture_files(name, types = [])
    types.each do |type|
      FileUtils.cp("spec/fixtures/sample.rxl", "spec/fixtures/#{name}.#{type}")
    end
  end
end
