require "spec_helper"

RSpec.describe "Relaton xml2htmlnew" do
  describe "relaton xml2htmlnew" do
    it "convers the xml file to xml" do
      allow(Relaton::Cli::YAMLConvertor).to receive(:to_html)
      command = %w(yaml2html samplenew.yaml style.css templates)

      Relaton::Cli.start(command)

      expect(Relaton::Cli::YAMLConvertor).to have_received(:to_html).
        with("samplenew.yaml", "style.css", "templates")
    end
  end
end
