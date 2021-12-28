require "fileutils"

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
        expect(content).to include("<bibdata type=\"standard\">")
      end
    end

    context "with Metanorma XML and different extension" do
      it "extracts XML in output directory with provided extension" do
        Relaton::Cli::RelatonFile.extract(
          "spec/assets/metanorma-xml",
          "./tmp/output", extension: "rxml"
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
          "spec/assets/metanorma-xml/a.xml",
          "./tmp/output", extension: "rxl"
        )

        content = File.read("./tmp/output/a.rxl")

        expect(file_exist?("a.rxl")).to be_truthy
        expect(file_exist?("cc-cor-12990-3.rxl")).to be_falsey
        expect(content).to include("<bibdata type=\"standard\">")
      end

      it "extracts the RFC in the output directory" do
        Relaton::Cli::RelatonFile.extract(
          "spec/fixtures/draft-celi-acvp-sha-00.xml",
          "./tmp/output", extension: "rxl"
        )

        content = File.read("./tmp/output/draft-celi-acvp-sha-00.rxl")

        expect(file_exist?("draft-celi-acvp-sha-00.rxl")).to be_truthy
        expect(file_exist?("cc-cor-12990-3.rxl")).to be_falsey
        expect(content).to include("<bibdata type=\"standard\">")
      end

      it "extract to current directory" do
        Relaton::Cli::RelatonFile.extract(
          "spec/fixtures/antioch.xml", "./tmp/output", extension: "rxl"
        )
        expect(File.read("./tmp/output/antioch.rxl")).to include(
          "<docnumber>draft-camelot-holy-grenade-01</docnumber>",
        )
      end
    end
  end

  describe ".concatenate" do
    context "with YAML & RXL files in source directory" do
      it "combines both type of files into a collection" do
        Relaton::Cli::RelatonFile.concatenate(
          "spec/fixtures", "./tmp/concatenate.yml", extension: "yml"
        )

        hashdoc = YAML.load_file("./tmp/concatenate.yml")

        expect(hashdoc["root"]["title"]).to be_nil
        expect(hashdoc["root"]["author"]).to be_nil

        items = hashdoc["root"]["items"]
        expect(items[0]["docid"]["id"]).to eq("CC 18001")
        expect(items[1]["docid"]["id"]).to eq("CC 36000")
        expect(items[2]["xml"]).not_to eq("spec/fixtures/sample-collection")
      end
    end

    context "with YAML, RXL files and custom options" do
      it "combines both type of files and usages the options" do
        Relaton::Cli::RelatonFile.concatenate(
          "spec/fixtures", "./tmp/concatenate.yml",
          title: "collection title", organization: "Ribose Inc",
          extension: "yml"
        )

        hashdoc = YAML.load_file("./tmp/concatenate.yml")

        expect(hashdoc["root"]["title"]).to eq("collection title")
        expect(hashdoc["root"]["author"]).to eq("Ribose Inc")
        expect(hashdoc["root"]["items"][1]["docid"]["id"]).to eq("CC 36000")
      end

      it "uses the new Relaton XML format" do
        Relaton::Cli::RelatonFile.concatenate(
          "spec/fixtures", "./tmp/concatenate.yml",
          title: "collection title", organization: "Ribose Inc",
          extension: "yml"
        )

        hashdoc = YAML.load_file("./tmp/concatenate.yml")
        items = hashdoc["root"]["items"].sort_by { |item| item["id"] }

        expect(hashdoc["root"]["title"]).to eq("collection title")
        expect(hashdoc["root"]["author"]).to eq("Ribose Inc")
        expect(items[3]["docid"]["id"]).to eq("CC 36000")
        expect(items[3]["docid"]["type"]).to eq("CC")
      end

      it "with IETF sample files" do
        file = "spec/fixtures/ietf_index.rxl"
        Relaton::Cli::RelatonFile.concatenate(
          "spec/fixtures/documents", file,
          title: "Collection title", organization: "Ribose",
          extension: "rxl"
        )

        content = File.read file, encoding: "UTF-8"
        expect(content).to include "<docidentifier>1149</docidentifier>"
        expect(content).to include '<uri type="rxl">spec/fixtures/documents/example.rxl</uri>'
        expect(content).to include "<docidentifier>draft-camelot-holy-grenade-01</docidentifier>"
        expect(content).to include '<uri type="rxl">spec/fixtures/documents/antioch.rxl</uri>'
      end
    end

    context "with YAML, RXL and linked documents" do
      it "combines documents and also add dynamic links" do
        file_types = ["xml", "pdf", "doc", "html"]
        create_fixture_files("sample", file_types)

        Relaton::Cli::RelatonFile.concatenate(
          "spec/fixtures", "./tmp/concatenate.yml", extension: "yml"
        )

        cleanup_fixture_files("sample", file_types)
        hashdoc = YAML.load_file("./tmp/concatenate.yml")
        items = hashdoc["root"]["items"]

        expect(hashdoc["root"]["title"]).to be_nil
        expect(hashdoc["root"]["author"]).to be_nil

        expect(items[0]["docid"]["id"]).to eq("CC 18001")
        expect(items[0]["link"].detect { |l| l["type"] == "xml" }["content"]).to eq("spec/fixtures/sample.xml")
        expect(items[0]["link"].detect { |l| l["type"] == "pdf" }["content"]).to eq("spec/fixtures/sample.pdf")
        expect(items[0]["link"].detect { |l| l["type"] == "doc" }["content"]).to eq("spec/fixtures/sample.doc")
        expect(items[0]["link"].detect { |l| l["type"] == "html" }["content"]).to eq("spec/fixtures/sample.html")
      end
    end
  end

  describe "split" do
    before { FileUtils.mkdir_p("./tmp/output") }
    after { FileUtils.rm_rf("./tmp/output") }

    context "with valid collection and output dir" do
      it "split the relaton collection into multiple files in XML format" do
        output_dir = "./tmp/output"
        collection_file = "spec/fixtures/sample-collection.xml"

        Relaton::Cli::RelatonFile.split(collection_file, output_dir, extension: "rxl")
        content = File.read([output_dir, "cc-34000.rxl"].join("/"))

        expect(file_exist?("cc-34000.rxl")).to be true
        expect(Dir["#{output_dir}/**"].length).to eq(6)
        expect(content).to include("<bibdata type=\"standard\">")
        expect(content).to include("<title>Date and time -- Concepts")
      end

      it "split the relaton collection into multiple files in YAML format" do
        output_dir = "./tmp/output"
        collection_file = "spec/fixtures/sample-collection.xml"

        Relaton::Cli::RelatonFile.split(collection_file, output_dir, new: true, extension: "yaml")
        content = File.read([output_dir, "cc-34000.yaml"].join("/"))

        expect(file_exist?("cc-34000.yaml")).to be true
        expect(Dir["#{output_dir}/**"].length).to eq(6)
        expect(content).to include("id: CC34000")
        expect(content).to include("title: Date and time -- Concepts and vocabulary")
      end

      it "split the relaton collection into default dir" do
        output_dir = "./sample-collection"
        collection_file = "spec/fixtures/sample-collection.xml"

        Relaton::Cli::RelatonFile.split(collection_file, nil, new: true, extension: "yaml")
        content = File.read([output_dir, "cc-34000.yaml"].join("/"))

        expect(File.exist?("#{output_dir}/cc-34000.yaml")).to be true
        expect(Dir["#{output_dir}/**"].length).to eq(6)
        expect(content).to include("id: CC34000")
        expect(content).to include("title: Date and time -- Concepts and vocabulary")
        FileUtils.rm_rf output_dir
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
