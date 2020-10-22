RSpec.describe Relaton::Cli::SubcommandCollection do
  it "create collection" do
    file = "collection.yaml"
    dir = "tmp"
    path = File.join dir, file
    Relaton::Cli::Command.start(
      [
        "collection", "create", file, "-d", dir, "--title", "Title",
        "--author", "Author", "--doctype", "ISO"
      ]
    )
    expect(File.exist?(path)).to be true
    yaml = YAML.load_file path
    expect(yaml["root"]["title"]).to eq "Title"
    expect(yaml["root"]["author"]).to eq "Author"
    expect(yaml["root"]["doctype"]).to eq "ISO"
    File.delete path
  end

  it "show info" do
    out = %r{
      Collection:\s.*?\n
      Last\supdated:\s\d{4}-\d{2}-\d{2}.*?\n
      File\ssize:\s\d+\n
      Number\sof\sitems:\s\d+\n
      Author:\s.*?\n
      Title:\s\w+
    }x
    expect do
      Relaton::Cli::Command.start(
        ["collection", "info", "spec/fixtures/sample-collection.yaml"]
      )
    end.to output(out).to_stdout
  end

  it "list collection" do
    expect do
      Relaton::Cli::Command.start(
        ["collection", "ls", "-d", "spec/fixtures"]
      )
    end.to output("sample-collection.yaml\n").to_stdout
  end

  context "get document by docid" do
    it "from specified collection" do
      expect do
        Relaton::Cli::Command.start(
          ["collection", "get", "CC 34005", "-c", "sample-collection.yaml",
           "-d", "spec/fixtures"]
        )
      end.to output(/<docidentifier type="CC">CC 34005/).to_stdout
    end

    it "across all collections" do
      expect do
        Relaton::Cli::Command.start(
          ["collection", "get", "CC 34005", "-d", "spec/fixtures"]
        )
      end.to output(/<docidentifier type="CC">CC 34005/).to_stdout
    end
  end

  context "search text" do
    it "in document identifier" do
      expect do
        Relaton::Cli::Command.start(
          ["collection", "search", "34006", "-d", "spec/fixtures"]
        )
      end.to output(/CC\/S \e\[4m34006\e\[24m/).to_stdout
    end

    it "in titles" do
      expect do
        Relaton::Cli::Command.start(
          ["collection", "search", "Calendars", "-d", "spec/fixtures"]
        )
      end.to output(
        /Date and time - \e\[4mCalendars\e\[24m - Gregorian calenda\.{3}/
      ).to_stdout
    end
  end

  context "fetch document" do
    it "and store into collection" do
      dir = "spec/fixtures"
      coll = "sample-collection.yaml"
      file = File.join dir, coll
      expect(File).to receive(:write).and_call_original
      expect(File).to receive(:write).with file, /CC\/DIR\s10005/, kind_of(Hash)

      VCR.use_cassette "cc_dir_10005" do
        Relaton::Cli::Command.start [
          "collection", "fetch", "CC/DIR 10005", "-t", "CC", "-d", dir,
          "-c", coll
        ]
      end
    end
  end

  context "import into collection an XML" do
    let(:dir) { "spec/fixtures" }
    let(:coll) { "sample-collection.yaml" }

    before(:example) do
      file = File.join dir, coll
      expect(File).to receive(:write).with file, /CC\s18001/, kind_of(Hash)
    end

    it "document" do
      Relaton::Cli::Command.start [
        "collection", "import", "spec/fixtures/sample.rxl", "-c", coll,
        "-d", dir
      ]
    end

    it "collection" do
      Relaton::Cli::Command.start [
        "collection", "import", "spec/fixtures/sample-coll.xml", "-c", coll,
        "-d", dir
      ]
    end
  end
end
