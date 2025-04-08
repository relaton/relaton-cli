RSpec.describe Relaton::Cli::XmlToHtmlRenderer do
  describe ".render" do
    it "generates the HTML output" do
      html = Relaton::Cli::XmlToHtmlRenderer.new(
        liquid_dir: "templates",
        stylesheet: "spec/assets/index-style.css",
      ).render(File.read("spec/assets/index.xml"))

      expect(html).to include("<html")
      expect(html).to include("<div class=\"document\"")
      expect(html).to include("CC/Amd 86003")
      expect(html).to include("CalConnect Inc\.")
      expect(html).to include("I AM A SAMPLE STYLESHEET")
      expect(html).to include("CalConnect Standards Registry")
      expect(html).to match(/<h3>[^{]+Date and time -- Timezone -- Timezone Manageme[^}]+</)
      expect(html).to match(/<h3>[^{]+Date and time -- Calendars -- Gregorian calendar[^}]+</)
      expect(html).to match(/<div class="doc-stage proposal">[\R\s]+proposal[\R\s]+<\/div>/)
      expect(html).to include("http://calconnect.org/pubdocs/CD0507%20CalDAV")
    end
  end

  describe "#uri_for_extension" do
    it "replace file extension with the provided one" do
      xmltohtml = Relaton::Cli::XmlToHtmlRenderer.new(
        stylesheet: "spec/assets/index-style.css",
        liquid_dir: "templates",
      )

      expect(
        xmltohtml.uri_for_extension("index.xml", "html"),
      ).to eq("index.html")
    end
  end
end
