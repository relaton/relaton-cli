RSpec.describe Relaton::Cli::SubcommandDb do
  let(:db) { double "DB" }
  let(:default_db_path) { "#{Dir.home}/.relaton/cache" }
  before(:each) do
    Relaton::Cli::RelatonDb.instance.instance_variable_set :@db, nil
  end

  context "create DB" do
    let(:custom_dir) { File.expand_path "custom_dir" }

    def db_mock(dir)
      db_cache = double "DbCache", dir: dir
      expect(db).to receive(:instance_variable_get).with(:@db)
        .and_return db_cache
      expect(Relaton::Db).to receive(:new).with(dir, nil).and_return db
    end

    it "in default dir" do
      expect(File).to receive(:exist?).with(Relaton::Cli::RelatonDb::DBCONF)
        .and_return false
      db_mock default_db_path
      expect { Relaton::Cli::Command.start ["db", "create"] }
        .to output(/Cache DB is in "#{default_db_path}"/).to_stderr
    end

    it "in specified dir" do
      expect(File).to receive(:write).with(
        Relaton::Cli::RelatonDb::DBCONF, custom_dir, encoding: "UTF-8"
      )
      db_mock custom_dir
      expect { Relaton::Cli::Command.start ["db", "create", "custom_dir"] }
        .to output(/Cache DB is in "#{custom_dir}"/).to_stderr
    end

    it "in dir from DB config" do
      expect(File).to receive(:exist?).with(Relaton::Cli::RelatonDb::DBCONF)
        .and_return true
      expect(File).to receive(:read).with(
        Relaton::Cli::RelatonDb::DBCONF, encoding: "UTF-8"
      ).and_return custom_dir
      db_mock custom_dir
      expect { Relaton::Cli::Command.start ["db", "create"] }
        .to output(/Cache DB is in "#{custom_dir}"/).to_stderr
    end
  end

  context do
    before(:each) { expect(Relaton::Db).to receive(:new).and_return db }

    let(:io) { double "IO" }

    it "move cache db" do
      new_dir = File.expand_path("new_dir")
      expect(File).to receive(:exist?).with(Relaton::Cli::RelatonDb::DBCONF)
        .and_return false
      expect(db).to receive(:mv).with(new_dir).and_return new_dir
      expect(File).to receive(:write)
        .with(Relaton::Cli::RelatonDb::DBCONF, new_dir, encoding: "UTF-8")
      expect { Relaton::Cli.start ["db", "mv", "new_dir"] }
        .to output(/Cache DB is moved to \"#{new_dir}\"/).to_stderr
    end

    it "clear cache DB" do
      expect(db).to receive(:clear)
      expect { Relaton::Cli.start ["db", "clear"] }
        .to output(/Cache DB is cleared/).to_stderr
    end

    it "fetch code from cache DB" do
      out = '<bibitem id="ISO2146"></bibitem>'
      bib = double "BibItem", to_xml: out
      expect(db).to receive(:fetch).with("ISO 2146", nil, fetch_db: true)
        .and_return bib
      expect(IO).to receive(:new).and_return io
      expect(io).to receive(:puts).with out
      Relaton::Cli.start ["db", "fetch", "ISO 2146"]
    end

    context "fetch all entries from cache DB" do
      before(:each) { expect(IO).to receive(:new).and_return io }

      context "return XML" do
        let(:out) { '<bibitem id="ISO2146"></bibitem>' }
        let(:bib) { double "BibItem", to_xml: out }

        before(:each) { expect(io).to receive(:puts).with(out) }

        it do
          expect(db).to receive(:fetch_all) do |arg|
            expect(arg).to be_nil
            [bib]
          end
          Relaton::Cli.start ["db", "fetch_all"]
        end

        it "filter by text" do
          expect(db).to receive(:fetch_all) do |arg|
            expect(arg).to eq "ISO 2146"
            [bib]
          end
          Relaton::Cli.start ["db", "fetch_all", "ISO 2146"]
        end

        it "filter by year" do
          expect(db).to receive(:fetch_all).with("ISO 2146", year: "2020")
            .and_return [bib]
          Relaton::Cli.start ["db", "fetch_all", "ISO 2146", "-y", "2020"]
        end

        it "filter by edition" do
          expect(db).to receive(:fetch_all).with("ISO 2146", edition: "2")
            .and_return [bib]
          Relaton::Cli.start ["db", "fetch_all", "ISO 2146", "-e", "2"]
        end
      end

      context "return YAML" do
        it do
          out = { title: "Title" }
          bib = double "BibItem", to_hash: out
          expect(io).to receive(:puts).with(out.to_yaml)
          expect(db).to receive(:fetch_all) do |arg|
            expect(arg).to be_nil
            [bib]
          end
          Relaton::Cli.start ["db", "fetch_all", "-f", "yaml"]
        end
      end

      context "return BibTex" do
        it do
          out = "@manual{ISOTC211, tile = {Geographic information}}"
          bib = double "BibItem", to_bibtex: out
          expect(io).to receive(:puts).with(out)
          expect(db).to receive(:fetch_all) do |arg|
            expect(arg).to be_nil
            [bib]
          end
          Relaton::Cli.start ["db", "fetch_all", "-f", "bibtex"]
        end
      end
    end
  end

  it "return document type" do
    io = double "IO"
    expect(IO).to receive(:new).and_return io
    expect(io).to receive(:puts).with(["Chinese Standard", "GB/T 1.1"])
    Relaton::Cli.start ["db", "doctype", "CN(GB/T 1.1)"]
  end
end
