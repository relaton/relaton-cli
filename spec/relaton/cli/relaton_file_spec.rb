require "fileutils"
require "spec_helper"

RSpec.describe Relaton::Cli::RelatonFile do
  describe ".extract" do
    before { FileUtils.mkdir_p("./tmp/output") }
    after { FileUtils.rm_rf("./tmp/output") }

    context "with Metanorma XML" do
      it "extracts Metanorma XML in the output directory" do
        Relaton::Cli::RelatonFile.extract(
          "spec/assets/metanorma-xml", "./tmp/output"
        )

        content = File.read("./tmp/output/a.rxl")

        expect(file_exist?("cc-amd-86003.rxl")).to be false
        expect(file_exist?("cc-cor-12990-3.rxl")).to be true
        expect(content).to include("<bibdata type='standard'>")
      end
    end

    context "with Metanorma XML and different extension" do
      it "extracts XML in output directory with provided extension" do
        Relaton::Cli::RelatonFile.extract(
          "spec/assets/metanorma-xml", "./tmp/output", extension: "rxml"
        )

        expect(file_exist?("a.rxl")).to be false
        expect(file_exist?("a.rxml")).to be true
        expect(file_exist?("cc-cor-12990-3.rxl")).to be false
        expect(file_exist?("cc-cor-12990-3.rxml")).to be true
      end
    end

    context "with single Metanorma XML file" do
      it "extracts the XML in the output directory" do
        Relaton::Cli::RelatonFile.extract(
          "spec/assets/metanorma-xml/a.xml", "./tmp/output"
        )

        content = File.read("./tmp/output/a.rxl")

        expect(file_exist?("a.rxl")).to be_truthy
        expect(file_exist?("cc-cor-12990-3.rxl")).to be_falsey
        expect(content).to include("<bibdata type='standard'>")
      end

      it "extracts the RFC in the output directory" do
        Relaton::Cli::RelatonFile.extract(
          "spec/fixtures/draft-celi-acvp-sha-00.xml", "./tmp/output"
        )

        content = File.read("./tmp/output/draft-celi-acvp-sha-00.rxl")

        expect(file_exist?("draft-celi-acvp-sha-00.rxl")).to be_truthy
        expect(file_exist?("cc-cor-12990-3.rxl")).to be_falsey
        expect(content).to include("<bibdata type='standard'>")
      end
    end
  end

  describe ".concatenate" do
    context "with YAML & RXL files in source directory" do
      it "combines both type of files into a collection" do
        Relaton::Cli::RelatonFile.concatenate(
          "spec/fixtures", "./tmp/concatenate.yml"
        )

        hashdoc = YAML.load_file("./tmp/concatenate.yml")

        expect(hashdoc["root"]["title"]).to be_nil
        expect(hashdoc["root"]["author"]).to be_nil

        items = hashdoc["root"]["items"]
        expect(items[0]["docidentifier"]).to eq("CC 18001")
        expect(items[1]["docidentifier"]).to eq("CC 36000")
        expect(items[2]["xml"]).not_to eq("spec/fixtures/sample-collection")
      end
    end

    context "with YAML, RXL files and custom options" do
      it "combines both type of files and usages the options" do
        Relaton::Cli::RelatonFile.concatenate(
          "spec/fixtures",
          "./tmp/concatenate.yml",
          title: "collection title",
          organization: "Ribose Inc",
        )

        hashdoc = YAML.load_file("./tmp/concatenate.yml")

        expect(hashdoc["root"]["title"]).to eq("collection title")
        expect(hashdoc["root"]["author"]).to eq("Ribose Inc")
        expect(hashdoc["root"]["items"][1]["docidentifier"]).to eq("CC 36000")
      end

      it "uses the new Relaton XML format" do
        Relaton::Cli::RelatonFile.concatenate(
          "spec/fixturesnew",
          "./tmp/concatenate.yml",
          title: "collection title",
          organization: "Ribose Inc",
          new: true,
        )

        hashdoc = YAML.load_file("./tmp/concatenate.yml")

        expect(hashdoc["root"]["title"]).to eq("collection title")
        expect(hashdoc["root"]["author"]).to eq("Ribose Inc")
        expect(hashdoc["root"]["items"][1]["docid"]["id"]).to eq("CC 36000")
        expect(hashdoc["root"]["items"][1]["docid"]["type"]).to eq("CC")
      end
    end

    context "with YAML, RXL and linked documents" do
      it "combines documents and also add dynamic links" do
        file_types = ["xml", "pdf", "doc", "html"]
        create_fixture_files("sample", file_types)

        Relaton::Cli::RelatonFile.concatenate(
          "spec/fixtures", "./tmp/concatenate.yml"
        )

        cleanup_fixture_files("sample", file_types)
        hashdoc = YAML.load_file("./tmp/concatenate.yml")
        items = hashdoc["root"]["items"]

        expect(hashdoc["root"]["title"]).to be_nil
        expect(hashdoc["root"]["author"]).to be_nil

        expect(items[0]["docidentifier"]).to eq("CC 18001")
        expect(items[0]["xml"]).to eq("spec/fixtures/sample.xml")
        expect(items[0]["pdf"]).to eq("spec/fixtures/sample.pdf")
        expect(items[0]["doc"]).to eq("spec/fixtures/sample.doc")
        expect(items[0]["html"]).to eq("spec/fixtures/sample.html")
      end
    end
  end

  describe "split" do
    before { FileUtils.mkdir_p("./tmp/output") }
    after { FileUtils.rm_rf("./tmp/output") }

    context "with valid collection and output dir" do
      it "split the relaton collection into multiple files" do
        output_dir = "./tmp/output"
        collection_file = "spec/fixtures/sample-collection.xml"

        Relaton::Cli::RelatonFile.split(collection_file, output_dir)
        content = File.read([output_dir, "cc-34000.rxl"].join("/"))

        expect(file_exist?("cc-34000.rxl")).to be true
        expect(Dir["#{output_dir}/**"].length).to eq(6)
        expect(content).to include("<bibdata type='standard'>")
        expect(content).to include("<title>Date and time -- Concepts")
      end

      it "split the relaton collection in the new Relaton XML format into multiple files" do
        output_dir = "./tmp/output"
        collection_file = "spec/fixturesnew/sample-collection.xml"

        Relaton::Cli::RelatonFile.split(collection_file, output_dir, new: true)
        content = File.read([output_dir, "cc-34000.rxl"].join("/"))

        expect(file_exist?("cc-34000.rxl")).to be true
        expect(Dir["#{output_dir}/**"].length).to eq(6)
        expect(content).to include('<bibdata type="standard">')
        expect(content).to include("<title>Date and time -- Concepts")
      end
    end
  end

  def file_exist?(file, directory = "./tmp/output")
    File.exist?([directory, file].join("/"))
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
