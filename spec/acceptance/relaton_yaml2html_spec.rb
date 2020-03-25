require "spec_helper"

RSpec.describe "Relaton yaml2html" do
  describe "relaton yaml2html" do
    it "convers the yaml file to html" do
      allow(Relaton::Cli::YAMLConvertor).to receive(:to_html)
      command = %w(yaml2html samplenew.yaml style.css templates)

      Relaton::Cli.start(command)

      expect(Relaton::Cli::YAMLConvertor).to have_received(:to_html).
        with("samplenew.yaml", "style.css", "templates")
    end
  end
end
