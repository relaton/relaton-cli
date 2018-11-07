require_relative "spec_helper"
require "fileutils"

RSpec.describe "extract" do
  it "extracts Metanorma XML" do
    FileUtils.rm_rf "spec/assets/out"
    FileUtils.mkdir_p "spec/assets/out"
    system "relaton extract spec/assets/metanorma-xml spec/assets/out"
    expect(File.exist?("spec/assets/out/CC-18001.rxl")).to be true
    expect(File.exist?("spec/assets/out/cc-18002.rxl")).to be false
    expect(File.exist?("spec/assets/out/cc-amd-86003.rxl")).to be false
    expect(File.exist?("spec/assets/out/cc-cor-12990-3.rxl")).to be true
    file = File.read("spec/assets/out/cc-18001.rxl", encoding: "utf-8")
    expect(file).to include "<bibdata"
  end

  it "extracts Metanorma XML with a different extension" do
    FileUtils.rm_rf "spec/assets/out"
    FileUtils.mkdir_p "spec/assets/out"
    system "relaton extract -x rxml spec/assets/metanorma-xml spec/assets/out"
    expect(File.exist?("spec/assets/out/CC-18001.rxl")).to be false
    expect(File.exist?("spec/assets/out/CC-18001.rxml")).to be true
    expect(File.exist?("spec/assets/out/cc-cor-12990-3.rxl")).to be false
    expect(File.exist?("spec/assets/out/cc-cor-12990-3.rxml")).to be true
  end
end

RSpec.describe "yaml2xml" do
  it "converts single entry from YAML to Relaton XML" do
    FileUtils.rm_rf "spec/assets/out"
    FileUtils.mkdir_p "spec/assets/out"
    FileUtils.cp "spec/assets/relaton-yaml/single.yaml", "spec/assets/out"
    system "relaton yaml2xml spec/assets/out/single.yaml"
    expect(File.exist?("spec/assets/out/single.rxl")).to be true
    expect(File.read("spec/assets/out/single.rxl")).to be_equivalent_to <<~"XML"
    <bibdata type='standard'>
<fetched>2018-11-03</fetched>
<title>Standardization documents -- Vocabulary</title>
<docidentifier>CC 36000</docidentifier>
<language></language>
<script></script>
<date type=''><on>2018-10-25</on></date>
<status>proposal</status>
<editorialgroup><technical-committee>PUBLISH</technical-committee></editorialgroup>
</bibdata>
    XML
  end

  it "converts single entry from YAML to Relaton XML with different prefix and extension nominated" do
    FileUtils.rm_rf "spec/assets/out"
    FileUtils.mkdir_p "spec/assets/out"
    FileUtils.cp "spec/assets/relaton-yaml/single.yaml", "spec/assets/out"
    system "relaton yaml2xml -p PREFIX -x rxml -o spec/assets spec/assets/out/single.yaml"
    expect(File.exist?("spec/assets/out/single.rxl")).to be false
    expect(File.exist?("spec/assets/out/single.rxml")).to be true
    expect(File.exist?("spec/assets/out/PREFIXsingle.rxml")).to be false
    expect(File.read("spec/assets/out/single.rxml")).to include "<bibdata"
  end

  it "converts collection from YAML to Relaton XML" do
    FileUtils.rm_rf "spec/assets/out"
    FileUtils.mkdir_p "spec/assets/out"
    FileUtils.cp "spec/assets/relaton-yaml/collection.yaml", "spec/assets/out"
    system "relaton yaml2xml spec/assets/out/collection.yaml"
    expect(File.exist?("spec/assets/out/collection.rxl")).to be true
    file = File.read("spec/assets/out/collection.rxl", encoding: "utf-8")
    expect(file).to include "<relaton-collection"
    expect(file).to include "Date and time -- Codes for calendar systems"
  end

  it "converts collection from YAML to Relaton XML with output directory" do
    FileUtils.rm_rf "spec/assets/out"
    FileUtils.mkdir_p "spec/assets/out"
    FileUtils.rm_rf "spec/assets/rxl"
    FileUtils.mkdir_p "spec/assets/rxl"
    FileUtils.cp "spec/assets/relaton-yaml/collection.yaml", "spec/assets/out"
    system "relaton yaml2xml -o spec/assets/rxl spec/assets/out/collection.yaml"
    expect(File.exist?("spec/assets/rxl/cc-34000.rxl")).to be true
    expect(File.read("spec/assets/rxl/cc-34000.rxl")).to include "<bibdata"
  end

  it "converts collection from YAML to Relaton XML with output directory, with different prefix and extension nominated" do
    FileUtils.rm_rf "spec/assets/out"
    FileUtils.mkdir_p "spec/assets/out"
    FileUtils.rm_rf "spec/assets/rxl"
    FileUtils.mkdir_p "spec/assets/rxl"
    FileUtils.cp "spec/assets/relaton-yaml/collection.yaml", "spec/assets/out"
    system "relaton yaml2xml -p PREFIX -x rxml -o spec/assets/rxl spec/assets/out/collection.yaml"
    expect(File.exist?("spec/assets/rxl/cc-34000.rxl")).to be false
    expect(File.exist?("spec/assets/rxl/PREFIXcc-34000.rxml")).to be true
    expect(File.read("spec/assets/rxl/PREFIXcc-34000.rxml")).to include "<bibdata"
  end
end

RSpec.describe "xml2yaml" do
  it "converts collection from XML to Relaton YAML" do
    FileUtils.rm_rf "spec/assets/out"
    FileUtils.mkdir_p "spec/assets/out"
    FileUtils.cp "spec/assets/collection.xml", "spec/assets/out"
    system "relaton xml2yaml spec/assets/out/collection.xml"
    expect(File.exist?("spec/assets/out/collection.yaml")).to be true
    file = File.read("spec/assets/out/collection.yaml", encoding: "utf-8")
    expect(file).to include <<~"YAML"
root:
  title: CalConnect Standards Registry
  items:
  - docidentifier: CC/R 3101
    doctype: report
YAML
  end

  it "converts collection from XML to Relaton YAML with output directory" do
    FileUtils.rm_rf "spec/assets/out"
    FileUtils.mkdir_p "spec/assets/out"
    FileUtils.rm_rf "spec/assets/rxl"
    FileUtils.mkdir_p "spec/assets/rxl"
    FileUtils.cp "spec/assets/collection.xml", "spec/assets/out"
    system "relaton xml2yaml -o spec/assets/rxl spec/assets/out/collection.xml"
    expect(File.exist?("spec/assets/rxl/cc-18001.yaml")).to be true
    expect(File.read("spec/assets/rxl/cc-18001.yaml")).to include <<~"YAML"
docidentifier: CC 18001
doctype: standard
YAML
  end

  it "converts collection from XML to Relaton YAML with output directory, with different prefix and extension nominated" do
    FileUtils.rm_rf "spec/assets/out"
    FileUtils.mkdir_p "spec/assets/out"
    FileUtils.rm_rf "spec/assets/rxl"
    FileUtils.mkdir_p "spec/assets/rxl"
    FileUtils.cp "spec/assets/collection.xml", "spec/assets/out"
    system "relaton xml2yaml -p PREFIX -x rxml -o spec/assets/rxl spec/assets/out/collection.xml"
    expect(File.exist?("spec/assets/rxl/cc-18001.yaml")).to be false
    expect(File.exist?("spec/assets/rxl/PREFIXcc-18001.rxml")).to be true
    expect(File.read("spec/assets/rxl/PREFIXcc-18001.rxml")).to include <<~"YAML"
docidentifier: CC 18001
doctype: standard
YAML
  end
end

RSpec.describe "xml2html" do
  it "converts Relaton XML to HTML" do
    FileUtils.rm_rf "spec/assets/collection.html"
    system "relaton xml2html spec/assets/collection.xml spec/assets/index-style.css spec/assets/templates"
    expect(File.exist?("spec/assets/collection.html")).to be true
    html = File.read("spec/assets/collection.html", encoding: "utf-8")
    expect(html).to include "I AM A SAMPLE STYLESHEET"
    expect(html).to include %(<a href="csd/cc-r-3101.html">CalConnect XLIII -- Position on the European Union daylight-savings timezone change</a>)
  end
end

RSpec.describe "yaml2html" do
  it "converts Relaton YAML to HTML" do
    FileUtils.rm_rf "spec/assets/relaton-yaml/collection.html"
    system "relaton yaml2html spec/assets/relaton-yaml/collection.yaml spec/assets/index-style.css spec/assets/templates"
    expect(File.exist?("spec/assets/relaton-yaml/collection.html")).to be true
    html = File.read("spec/assets/relaton-yaml/collection.html", encoding: "utf-8")
    expect(html).to include "I AM A SAMPLE STYLESHEET"
    expect(html).to include %(<a href="">CC 34000</a>)
  end
end

RSpec.describe "concatenate" do
  it "concatenates YAML and RXL into a collection" do
    FileUtils.rm_rf "spec/assets/rxl"
    FileUtils.mkdir_p "spec/assets/rxl"
    FileUtils.rm_f "spec/assets/concatenate.rxl"
    FileUtils.cp "spec/assets/relaton-yaml/single.yaml", "spec/assets/rxl"
    FileUtils.cp "spec/assets/relaton-xml/CC-18001.rxl", "spec/assets/rxl"
    FileUtils.cp "spec/assets/index.xml", "spec/assets/rxl"
    system "relaton concatenate spec/assets/rxl spec/assets/concatenate.rxl"
    expect(File.exist?("spec/assets/concatenate.rxl")).to be true
    xml = File.read("spec/assets/concatenate.rxl")
    expect(xml).to include "<docidentifier>CC 36000</docidentifier>"
    expect(xml).to include "<docidentifier>CC 18001</docidentifier>"
    expect(xml).not_to include "<docidentifier>CC/R 3101</docidentifier>"
    expect(xml).not_to include %(<uri type='xml'>spec/assets/rxl/CC-18001.xml</uri>)
    expect(xml).not_to include %(<uri type='html'>spec/assets/rxl/CC-18001.html</uri>)
    expect(xml).not_to include %(<uri type='pdf'>spec/assets/rxl/CC-18001.pdf</uri>)
    expect(xml).not_to include %(<uri type='doc'>spec/assets/rxl/CC-18001.doc</uri>)
    xmldoc = Nokogiri::XML(xml)
    expect(xmldoc.root.at("./xmlns:title")).to be_nil
    expect(xmldoc.root.at("./xmlns:contributor")).to be_nil
  end

  it "creates document links dynamically" do
    FileUtils.rm_rf "spec/assets/rxl"
    FileUtils.mkdir_p "spec/assets/rxl"
    FileUtils.rm_f "spec/assets/concatenate.rxl"
    FileUtils.cp "spec/assets/relaton-xml/CC-18001.rxl", "spec/assets/rxl"
    File.open("spec/assets/rxl/CC-18001.xml", "w") { |f| f.write "..." }
    File.open("spec/assets/rxl/CC-18001.pdf", "w") { |f| f.write "..." }
    File.open("spec/assets/rxl/CC-18001.doc", "w") { |f| f.write "..." }
    File.open("spec/assets/rxl/CC-18001.html", "w") { |f| f.write "..." }
    system "relaton concatenate spec/assets/rxl spec/assets/concatenate.rxl"
    expect(File.exist?("spec/assets/concatenate.rxl")).to be true
    xml = File.read("spec/assets/concatenate.rxl")
    expect(xml).to include %(<uri type='xml'>spec/assets/rxl/CC-18001.xml</uri>)
    expect(xml).to include %(<uri type='html'>spec/assets/rxl/CC-18001.html</uri>)
    expect(xml).to include %(<uri type='pdf'>spec/assets/rxl/CC-18001.pdf</uri>)
    expect(xml).to include %(<uri type='doc'>spec/assets/rxl/CC-18001.doc</uri>)
  end

  it "creates collection with title and author" do
    FileUtils.rm_rf "spec/assets/rxl"
    FileUtils.mkdir_p "spec/assets/rxl"
    FileUtils.rm_f "spec/assets/concatenate.rxl"
    FileUtils.cp "spec/assets/relaton-xml/CC-18001.rxl", "spec/assets/rxl"
    system "relaton concatenate -t TITLE -g ORG spec/assets/rxl spec/assets/concatenate.rxl"
    expect(File.exist?("spec/assets/concatenate.rxl")).to be true
    xml = File.read("spec/assets/concatenate.rxl")
    xmldoc = Nokogiri::XML(xml)
    expect(xmldoc.root.at("./xmlns:title")).not_to be_nil
    expect(xmldoc.root.at("./xmlns:contributor")).not_to be_nil
    expect(xmldoc.root.at("./xmlns:title").text).to eq "TITLE"
    expect(xmldoc.root.at("./xmlns:contributor/xmlns:organization/xmlns:name").text).to eq "ORG"
  end
end


