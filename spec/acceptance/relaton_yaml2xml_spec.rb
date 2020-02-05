require "spec_helper"

RSpec.describe "Relaton yaml2xml" do
  describe "relaton yaml2xml" do
    context "yaml file without any option" do
      it "sends convertion message to the convertaor" do
        allow(Relaton::Cli::YAMLConvertor).to receive(:to_xml)

        command = %w(yaml2xml spec/fixturesnew/samplenew.yaml)
        Relaton::Cli.start(command)

        expect(Relaton::Cli::YAMLConvertor).to have_received(:to_xml).
          with("spec/fixturesnew/samplenew.yaml", overwrite: false, extension: "rxl")
      end
    end

    context "yaml file with options" do
      it "sends convertion message with file and options" do
        allow(Relaton::Cli::YAMLConvertor).to receive(:to_xml)

        command = %w(yaml2xml spec/fixturesnew/samplenew.yaml -x rxml -p RCL)
        Relaton::Cli.start(command)

        expect(Relaton::Cli::YAMLConvertor).to have_received(:to_xml).with(
          "spec/fixturesnew/samplenew.yaml",
          extension: "rxml",
          prefix: "RCL",
          overwrite: false,
        )
      end
    end
  end
end
