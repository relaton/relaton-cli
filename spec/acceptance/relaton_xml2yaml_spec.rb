require "spec_helper"

RSpec.describe "Relaton xml2yaml" do
  describe "relaton xml2yaml" do
    context "xml file without any option specified" do
      it "sends convertion message to the convertaor" do
        allow(Relaton::Cli::XMLConvertor).to receive(:to_yaml)

        command = %w(xml2yaml spec/fixtures/sample-collection.xml)
        Relaton::Cli.start(command)

        expect(Relaton::Cli::XMLConvertor).to have_received(:to_yaml).
          with("spec/fixtures/sample-collection.xml", overwrite: false, extension: "yaml")
      end
    end

    context "xml file with custom option specified" do
      it "sends convertion message with custom options" do
        allow(Relaton::Cli::XMLConvertor).to receive(:to_yaml)

        command = %w(xml2yaml spec/fixtures/sample.xml -x yaml -p RCL)
        Relaton::Cli.start(command)

        expect(Relaton::Cli::XMLConvertor).to have_received(:to_yaml).with(
          "spec/fixtures/sample.xml",
          extension: "yaml",
          prefix: "RCL",
          overwrite: false,
        )
      end
    end
  end
end
