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

    context "with markup and entities in the collection title and author" do
      let(:html) do
        renderer.render(File.read("spec/assets/index-with-markup.xml"))
      end

      it "preserves <strong> markup and &amp; in the coverpage title" do
        expect(html).to include(
          '<span class="title-first">Use of <strong>ActualText</strong> ' \
          "&amp; <strong>Reference</strong> structure elements</span>",
        )
      end

      it "strips inline tags but keeps &amp; in <head><title>" do
        head_title = html[/<title>([^<]*(?:<(?!\/title)[^<]*)*)<\/title>/m, 1]
        expect(head_title).to include("&amp;")
        expect(head_title).not_to include("<strong>")
      end

      it "preserves &amp; in the rendered author" do
        expect(html).to include("Acme &amp; Co")
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
