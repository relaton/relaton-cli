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
    FileUtils.rm_rf "spec/assets/relaton-xml"
    FileUtils.mkdir_p "spec/assets/relaton-xml"
    system "relaton extract spec/assets/metanorma-xml spec/assets/relaton-xml"
    expect(File.exist?("spec/assets/relaton-xml/CC-18001.rxl")).to be true
    expect(File.exist?("spec/assets/relaton-xml/cc-18002.rxl")).to be false
    expect(File.exist?("spec/assets/relaton-xml/cc-amd-86003.rxl")).to be false
    expect(File.exist?("spec/assets/relaton-xml/cc-cor-12990-3.rxl")).to be true
    file = File.read("spec/assets/relaton-xml/cc-18001.rxl", encoding: "utf-8")
    expect(file).to include "<bibdata"
  end

  it "extracts Metanorma XMLwith a different extension" do
    FileUtils.rm_rf "spec/assets/relaton-xml"
    FileUtils.mkdir_p "spec/assets/relaton-xml"
    system "relaton extract -x rxml spec/assets/metanorma-xml spec/assets/relaton-xml"
    expect(File.exist?("spec/assets/relaton-xml/CC-18001.rxl")).to be false
    expect(File.exist?("spec/assets/relaton-xml/CC-18001.rxml")).to be true
    expect(File.exist?("spec/assets/relaton-xml/cc-cor-12990-3.rxl")).to be false
    expect(File.exist?("spec/assets/relaton-xml/cc-cor-12990-3.rxml")).to be true
  end
end


