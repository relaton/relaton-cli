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

# RSpec.describe "yaml2html", skip: true do
#   it "converts Relaton YAML to HTML" do
#     FileUtils.rm_rf "spec/assets/relaton-yaml/collection.html"
#     system "relaton yaml2html spec/assets/relaton-yaml/collection.yaml spec/assets/index-style.css spec/assets/templates"
#     expect(File.exist?("spec/assets/relaton-yaml/collection.html")).to be true
#     html = File.read("spec/assets/relaton-yaml/collection.html", encoding: "utf-8")
#     expect(html).to include "I AM A SAMPLE STYLESHEET"
#     expect(html).to include %(<a href="">CC 34000</a>)
#   end
# end


