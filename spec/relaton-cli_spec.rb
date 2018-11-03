require_relative "spec_helper"
require "fileutils"

RSpec.describe "fetch" do
  context "fetches code" do
    command "relaton fetch -t ISO 'ISO 2146'"
    its(:stdout) { is_expected.to include %(<docidentifier type="ISO">ISO 2146</docidentifier>) }
    its(:stdout) { is_expected.to include %(<relation type="instance">) }
  end
  context "fetches dated code" do
    command "relaton fetch -t ISO -y 2010 'ISO 2146'"
    its(:stdout) { is_expected.to include %(<docidentifier type="ISO">ISO 2146:2010</docidentifier>) }
    its(:stdout) { is_expected.not_to include %(<relation type="instance">) }
  end
  context "warns when fetch askes for wrong date" do
    command "relaton fetch -t ISO -y 2009 'ISO 2146'"
    its(:stdout) { is_expected.to include "No matching bibliographic entry found" }
  end
  context "warns when fetch gives no type" do
    command "relaton fetch 'ISO 170'"
    its(:stderr) { is_expected.to include "No value provided for required options '--type'" }
  end
  context "warns when fetch uses unsupported type" do
    command "relaton fetch -t xyz 'ISO 170'"
    its(:stdout) { is_expected.to include "Recognised types:" }
  end
  context "warns when fetch targets an undefined standard" do
    command "relaton fetch -t ISO 'ISO ABC'"
    its(:stdout) { is_expected.to include "No matching bibliographic entry found" }
  end
end

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
  it "is not yet implemented" do
    expect(true).to be false
  end
end

RSpec.describe "xml2html" do
  it "is not yet implemented" do
    expect(true).to be false
  end
end

RSpec.describe "concatenate" do
  it "is not yet implemented" do
    expect(true).to be false
  end
end

RSpec.describe "yaml2html" do
  it "is not yet implemented" do
    expect(true).to be false
  end
end


