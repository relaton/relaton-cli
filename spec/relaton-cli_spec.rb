require_relative "spec_helper"
require "fileutils"

RSpec.describe "extract", skip: true do
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
