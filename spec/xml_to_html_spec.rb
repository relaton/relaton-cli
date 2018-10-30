require_relative "spec_helper"

RSpec.describe Relaton::Cli::XmlToHtmlRenderer do
  it "generates HTML output" do
    xmltohtml = Relaton::Cli::XmlToHtmlRenderer.new(stylesheet: "spec/assets/index-style.css", liquid_dir: "templates")
    html = xmltohtml.render(File.read("spec/assets/index.xml", encoding: "UTF-8"))
    File.open("html.html", 'w') { |file| file.write(html) }
    expect(html).to match /<html/
    # reads default stylesheet
    expect(html).to match /I AM A SAMPLE STYLESHEET/
    expect(html).to match /CalConnect Standards Registry/
    expect(html).to match /CalConnect Inc\./
    expect(html).to match /Date and time -- Timezone -- Timezone Management/
    expect(html).to include "http://calconnect.org/pubdocs/CD0507%20CalDAV%20Use%20Cases%20V1.0.pdf"
    expect(html).to include "CC/Amd 86003"
  end
end

