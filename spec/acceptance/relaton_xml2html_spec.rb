require "spec_helper"

RSpec.describe "Relaton xml2html" do
  describe "relaton xml2html" do
    it "convers the xml file to xml" do
      allow(Relaton::Cli::XMLConvertor).to receive(:to_html)
      command = %w(xml2html sample.xml style.css templates)

      Relaton::Cli.start(command)

      expect(Relaton::Cli::XMLConvertor).to have_received(:to_html).
        with("sample.xml", "style.css", "templates")
    end
  end
end
