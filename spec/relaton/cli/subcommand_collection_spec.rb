RSpec.describe Relaton::Cli::SubcommandCollection do
  let(:dir) { "spec/fixtures" }

  context "create collection" do
    it do
      file = "collection.yaml"
      tmp = "tmp"
      path = File.join tmp, file
      Relaton::Cli::Command.start(
        [
          "collection", "create", file, "-d", tmp, "--title", "Title",
          "--author", "Author", "--doctype", "ISO"
        ],
      )
      expect(File.exist?(path)).to be true
      yaml = YAML.load_file path
      expect(yaml["root"]["title"]).to eq "Title"
      expect(yaml["root"]["author"]).to eq "Author"
      expect(yaml["root"]["doctype"]).to eq "ISO"
      File.delete path
    end

    it "out error mesage" do
      file = "sample-collection.yaml"
      expect do
        Relaton::Cli::Command.start ["collection", "create", file, "-d", dir]
      end.to output(/Collection #{file} aready exist/).to_stderr
    end
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
        ["collection", "info", "sample-collection.yaml", "-d", dir],
      )
    end.to output(out).to_stdout
  end

  context "list" do
    it "collections" do
      expect do
        Relaton::Cli::Command.start(
          ["collection", "ls", "-d", dir],
        )
      end.to output("sample-collection.yaml\n").to_stdout
    end

    it "entries" do
      expect do
        Relaton::Cli::Command.start(
          ["collection", "ls", "-e", "-d", dir],
        )
      end.to output(/CC 36000/).to_stdout
    end
  end

  context "get document by docid" do
    shared_examples "get" do |collection, format|
      it do
        args = ["collection", "get", "CC 34005", "-d", dir]
        args += ["-c", collection] if collection
        args += ["-f", format] if format
        expect { Relaton::Cli::Command.start args }.to output(out_regex)
          .to_stdout
      end
    end

    context do
      let(:out_regex) { /Document identifier: CC 34005/ }

      context "from specified collection" do
        include_examples "get", "sample-collection.yaml"
      end

      context("across all collections") { include_examples "get" }
    end

    context "and output it in" do
      context "Asciibib format" do
        let(:out_regex) { /id:: CC34005/ }
        include_examples "get", nil, "abb"
      end

      context "XML format" do
        let(:out_regex) { /<docidentifier type="CC">CC 34005/ }
        include_examples "get", nil, "xml"
      end
    end

    context "and write it to" do
      it "Asciibib file" do
        file = "tmp/cc_34005.abb"
        expect(File).to receive(:write).with file, /id:: CC34005/, kind_of(Hash)
        Relaton::Cli::Command.start(
          ["collection", "get", "CC 34005", "-d", dir, "-o", file],
        )
      end

      it "XML file" do
        file = "tmp/cc_34005.xml"
        expect(File).to receive(:write).with(
          file, /<docidentifier type="CC">CC 34005/, kind_of(Hash)
        )
        Relaton::Cli::Command.start(
          ["collection", "get", "CC 34005", "-d", dir, "-o", file],
        )
      end
    end
  end

  context "search text in" do
    shared_examples "search" do |text, regex|
      it "of collection" do
        expect do
          Relaton::Cli::Command.start ["collection", "search", text, "-d", dir]
        end.to output(regex).to_stdout
      end
    end

    context "document identifiers" do
      include_examples "search", "34006", /CC\/S \e\[4m34006\e\[24m/
    end

    context "in titles" do
      include_examples(
        "search", "Calendars",
        /Date and time - \e\[4mCalendars\e\[24m - Gregorian calenda\.{3}/
      )
    end
  end

  context "fetch document" do
    it "and store into collection" do
      dir = "spec/fixtures"
      coll = "sample-collection.yaml"
      file = File.join dir, coll
      expect(File).to receive(:write).with(file, /CC\/DIR\s10005/, kind_of(Hash)).at_most :once
      expect(File).to receive(:write).and_call_original.at_most(5).times
      expect(File).to receive(:exist?).with(/etag\.txt/).and_return false
      expect(File).to receive(:exist?).with(/bibliography\.yml/).and_return false
      expect(File).to receive(:exist?).and_call_original.at_least :once

      VCR.use_cassette "cc_dir_10005" do
        Relaton::Cli::Command.start [
          "collection", "fetch", "CC/DIR 10005", "-t", "CC", "-d", dir,
          "-c", coll
        ]
      end
    end
  end

  it "export collection" do
    dir = "spec/fixtures"
    file = "sample-collection.yaml"
    outfile = "#{file.sub(/\.\w+$/, '')}.xml"
    expect(File).to receive(:write).with(
      outfile, /<docidentifier type="CC">CC\s36000<\/docidentifier>/,
      kind_of(Hash)
    )
    Relaton::Cli::Command.start ["collection", "export", file, "-d", dir]
  end

  context "import" do
    before(:example) do
      file = File.join dir, coll
      expect(File).to receive(:write).with file, /CC\s18001/, kind_of(Hash)
    end

    shared_examples "import" do |source|
      it "XML" do
        Relaton::Cli::Command.start [
          "collection", "import", source, "-c", coll, "-d", dir
        ]
      end
    end

    context "into existed collection" do
      let(:coll) { "sample-collection.yaml" }

      include_examples "import", "spec/fixtures/sample.rxl"
      include_examples "import", "spec/fixtures/sample-coll.xml"
    end

    context "into new collection" do
      let(:coll) { "no-exist-collection.yaml" }

      include_examples "import", "spec/fixtures/sample.rxl"
      include_examples "import", "spec/fixtures/sample-coll.xml"
    end
  end
end
