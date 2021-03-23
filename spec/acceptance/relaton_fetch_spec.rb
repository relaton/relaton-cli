# frozen_string_literal: true

require "open3"

RSpec.describe "Relaton Fetch" do
  describe "relaton fetch" do
    it "calls fetch" do
      db = double
      expect(db).to receive(:fetch).with("ISO 2146", nil)
      expect(Relaton::Cli).to receive(:relaton).and_return(db).exactly(2).times

      command = ["fetch", "--type", "ISO", "ISO 2146"]
      Relaton::Cli.start(command)
    end

    it "calls fetch with lowercase type" do
      db = double
      expect(db).to receive(:fetch).with("ISO 2146", nil)
      expect(Relaton::Cli).to receive(:relaton).and_return(db).exactly(2).times

      command = ["fetch", "--type", "iso", "ISO 2146"]
      Relaton::Cli.start(command)
    end

    context "fetch code with a type" do
      it "prints out the document for valid code and type" do
        output = `relaton fetch --type ISO 'ISO 2146'`

        expect(output).to include('<relation type="obsoletes">')
        expect(output).to include('<docidentifier type="ISO">ISO 2146')
      end

      it "prints out the document in BibTeX format" do
        output = `relaton fetch --format bibtex --type ISO 'ISO 2146'`
        expect(output).to include("@misc{ISO2146(allparts),")
      end
    end

    context "fetch code with date specified" do
      it "prints out the correct document for valid date" do
        output = `relaton fetch -t ISO -y 2010 'ISO 2146'`

        expect(output).to include('<relation type="obsoletes">')
        expect(output).to include('<docidentifier type="ISO">ISO 2146')
      end

      it "prints out a warning messages for wrong date" do
        output = `relaton fetch -t ISO -y 2009 'ISO 2146'`
        expect(output).to include("No matching bibliographic entry")
      end
    end

    context "fetch code with invalid/missing type" do
      it "calls supported_type_message method" do
        io = double "IO"
        expect(io).to receive(:puts).with "Recognised types: BIPM, CC, CIE, CN, ECMA, "\
        "IEC, IEEE, IETF, IHO, ISO, ITU, NIST, OGC, OMG, UN, W3C"
        expect(IO).to receive(:new).with(kind_of(Integer), mode: "w:UTF-8")
          .and_return io
        command = Relaton::Cli::Command.new
        command.fetch ["ISO 2146", "--type", "invalid"]
      end

      it "prints a warning message for missing --type option" do
        _, stderr, = Open3.capture3("relaton fetch 'ISO 2146'")
        expect(stderr).to include("required options '--type'")
      end

      it "prints a warning message with suggestions for invalid type" do
        output = `relaton fetch 'ISO 2146' --type invalid`
        expect(output).to include(
          "Recognised types: BIPM, CC, CIE, CN, ECMA, IEC, IEEE, IETF, IHO, ISO, ITU, NIST, OGC, OMG, UN, W3C"
        )
      end
    end

    context "fetch code with undefined standard" do
      it "prints out a warning message for undefined standard" do
        output = `relaton fetch -t ISO 'ISO ABCDEFGH'`
        expect(output).to include("No matching bibliographic entry found")
      end
    end

    it "raise request error" do
      relaton = double("relaton")
      expect(relaton).to receive(:fetch).and_raise RelatonBib::RequestError
      expect(Relaton::Db).to receive(:new).and_return relaton
      command = Relaton::Cli::Command.new
      expect(command).to receive(:registered_types).and_return ["ISO"]
      expect(command.send(:fetch_document, "ISO 2146", type: "ISO")).to eq(
        "RelatonBib::RequestError"
      )
      Relaton::Cli::RelatonDb.instance.instance_variable_set :@db, nil
    end
  end
end
