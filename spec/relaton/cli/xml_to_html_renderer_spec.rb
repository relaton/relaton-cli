RSpec.describe Relaton::Cli::XmlToHtmlRenderer do

  let(:document) do
    parse_html(html)
  end

  let(:renderer) do
    Relaton::Cli::XmlToHtmlRenderer.new(
      liquid_dir: "templates",
      stylesheet: "spec/assets/index-style.css",
    )
  end

  describe ".render" do
    context "with a document containing a stylesheet" do
      let(:html) do
        renderer.render(File.read("spec/assets/index.xml"))
      end

      it "generates the HTML output" do
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

    context "with a document containing other collections" do
      let(:html) do
        renderer.render(File.read("spec/assets/with-collections.xml"))
      end

      it "renders links with relative paths" do
        document.div(class: "document").a.all.each do |a|
          expect(Pathname.new(a[:href])).to be_relative
        end
      end

      context "for the only rendered document" do
        subject(:section) do
          document.div(class: 'document')[1]
        end

        it "renders with stage" do
          expect(section).to have_css(".doc-stage")
          expect(section.div(class: "doc-info")[:class]).to match 'draft'
          expect(section.div(class: "doc-stage")[:class]).to match 'draft'
        end
      end

      context "for the rendered collections" do
        it "renders without stage" do
          (2..3).map do |i|
            document.div(class: 'document')[i]
          end.each do |e|
            expect(e).to_not have_css(".doc-info")
            expect(e).to_not have_css(".doc-stage")
          end
        end
      end

    end

  end

  describe "#uri_for_extension" do
    it "replace file extension with the provided one" do
      expect(
        renderer.uri_for_extension("index.xml", "html"),
      ).to eq("index.html")
    end
  end
end
