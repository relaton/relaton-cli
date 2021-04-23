# frozen_string_literal: true

# require "open3"

RSpec.describe "Relaton Fetch" do
  describe "relaton fetch" do
    it "calls fetch" do
      db = double
      expect(db).to receive(:fetch_std)
        .with("ISO 2146", nil, :relaton_iso, type: "ISO")
      expect(Relaton::Cli).to receive(:relaton).and_return(db)

      command = ["fetch", "--type", "ISO", "ISO 2146"]
      Relaton::Cli.start(command)
    end

    it "calls fetch with lowercase type" do
      db = double
      expect(db).to receive(:fetch_std)
        .with("ISO 2146", nil, :relaton_iso, type: "iso")
      expect(Relaton::Cli).to receive(:relaton).and_return(db)

      command = ["fetch", "--type", "iso", "ISO 2146"]
      Relaton::Cli.start(command)
    end

    context do
      let(:io) { double "IO" }
      before (:each) do
        RSpec::Mocks.space.proxy_for(IO).reset
        expect(IO).to receive(:new) do |arg1, arg2, &_block|
          if arg1.is_a?(Integer) then io
          else yield arg1, arg2
          end
        end.at_most(2).times
      end

      it "calls fetch and return XML" do
        expect(io).to receive(:puts) do |arg|
          expect(arg).to include '<docidentifier type="ISO">ISO 2146 (all parts)'\
            "</docidentifier>"
        end
        VCR.use_cassette "iso_2146" do
          command = ["fetch", "--type", "iso", "ISO 2146"]
          Relaton::Cli.start(command)
        end
      end

      it "calls fetch and return YAML" do
        expect(io).to receive(:puts) do |arg|
          expect(arg).to include "- id: ISO 2146 (all parts)"
        end
        VCR.use_cassette "iso_2146" do
          command = ["fetch", "--type", "iso", "--format", "yaml", "ISO 2146"]
          Relaton::Cli.start(command)
        end
      end

      it "calls fetch and return BibTex" do
        expect(io).to receive(:puts) do |arg|
          expect(arg).to include "@misc{ISO2146(allparts)"
        end
        VCR.use_cassette "iso_2146" do
          command = ["fetch", "--type", "iso", "--format", "bibtex", "ISO 2146"]
          Relaton::Cli.start(command)
        end
      end
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
        expect(io).to receive(:puts).with "Recognised types: BIPM, BSI, CC, "\
        "CIE, CN, ECMA, IEC, IEEE, IETF, IHO, ISO, ITU, NIST, OGC, OMG, UN, W3C"
        expect(IO).to receive(:new).with(kind_of(Integer), mode: "w:UTF-8")
          .and_return io
        Relaton::Cli.start ["fetch", "ISO 2146", "--type", "invalid"]
      end

      # it "prints a warning message for missing --type option" do
      #   _, stderr, = Open3.capture3("relaton fetch 'ISO 2146'")
      #   expect(stderr).to include("required options '--type'")
      # end

      it "prints a warning message with suggestions for invalid type" do
        output = `relaton fetch 'ISO 2146' --type invalid`
        expect(output).to include(
          "Recognised types: BIPM, BSI, CC, CIE, CN, ECMA, IEC, IEEE, IETF, "\
          "IHO, ISO, ITU, NIST, OGC, OMG, UN, W3C"
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
      db = double("DB")
      expect(db).to receive(:fetch_std).and_raise RelatonBib::RequestError
      expect(Relaton::Cli).to receive(:relaton).and_return(db)
      command = Relaton::Cli::Command.new
      # expect(command).to receive(:registered_types).and_return ["ISO"]
      expect(command.send(:fetch_document, "ISO 2146", type: "ISO")).to eq(
        "RelatonBib::RequestError"
      )
      Relaton::Cli::RelatonDb.instance.instance_variable_set :@db, nil
    end
  end
end
