require "spec_helper"

RSpec.describe "Relaton yaml2xmlnew" do
  describe "relaton yaml2xmlnew" do
    context "yaml file without any option" do
      it "sends convertion message to the convertaor" do
        allow(Relaton::Cli::YAMLConvertorNew).to receive(:to_xml)

        command = %w(yaml2xmlnew spec/fixturesnew/samplenew.yaml)
        Relaton::Cli.start(command)

        expect(Relaton::Cli::YAMLConvertorNew).to have_received(:to_xml).
          with("spec/fixturesnew/samplenew.yaml", overwrite: false, extension: "rxl")
      end
    end

    context "yaml file with options" do
      it "sends convertion message with file and options" do
        allow(Relaton::Cli::YAMLConvertorNew).to receive(:to_xml)

        command = %w(yaml2xmlnew spec/fixturesnew/samplenew.yaml -x rxml -p RCL)
        Relaton::Cli.start(command)

        expect(Relaton::Cli::YAMLConvertorNew).to have_received(:to_xml).with(
          "spec/fixturesnew/samplenew.yaml",
          extension: "rxml",
          prefix: "RCL",
          overwrite: false,
        )
      end
    end
  end
end
