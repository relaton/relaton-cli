require "spec_helper"

RSpec.describe "Relaton xml2htmlnew" do
  describe "relaton xml2htmlnew" do
    it "convers the xml file to xml" do
      allow(Relaton::Cli::YAMLConvertorNew).to receive(:to_html)
      command = %w(yaml2htmlnew samplenew.yaml style.css templates)

      Relaton::Cli.start(command)

      expect(Relaton::Cli::YAMLConvertorNew).to have_received(:to_html).
        with("samplenew.yaml", "style.css", "templates")
    end
  end
end
