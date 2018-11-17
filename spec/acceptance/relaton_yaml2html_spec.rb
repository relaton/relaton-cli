require "spec_helper"

RSpec.describe "Relaton xml2html" do
  describe "relaton xml2html" do
    it "convers the xml file to xml" do
      allow(Relaton::Cli::YAMLConvertor).to receive(:to_html)
      command = %w(yaml2html sample.yaml style.css templates)

      Relaton::Cli.start(command)

      expect(Relaton::Cli::YAMLConvertor).to have_received(:to_html).
        with("sample.yaml", "style.css", "templates")
    end
  end
end
