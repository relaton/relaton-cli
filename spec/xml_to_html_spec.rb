require_relative "spec_helper"

RSpec.describe Relaton::Cli::XmlToHtmlRenderer do
  it "generates HTML output" do
    xmltohtml = Relaton::Cli::XmlToHtmlRenderer.new(stylesheet: "spec/assets/index-style.css", liquid_dir: "templates")
    html = xmltohtml.render(File.read("spec/assets/index.xml", encoding: "UTF-8"))
    expect(html).to match /<html/
  end
end

