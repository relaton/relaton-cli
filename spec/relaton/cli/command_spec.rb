RSpec.describe Relaton::Cli::Command do
  context "convert Relaton XML document" do
    it "to YAML" do
      file = "spec/fixtures/bib_item.xml"
      output = "spec/fixtures/bib_item.yaml"
      Relaton::Cli::Command.start ["convert", file, "-f", "yaml"]
      expect(File.exist?(output)).to be true
      File.delete output
    end

    it "to BibTex" do
      file = "spec/fixtures/bib_item.xml"
      output = "spec/fixtures/bib_item.bib"
      Relaton::Cli::Command.start ["convert", file, "-f", "bibtex"]
      expect(File.exist?(output)).to be true
      File.delete output
    end

    it "to AsciiBib" do
      file = "spec/fixtures/bib_item.xml"
      output = "spec/fixtures/bib_item.adoc"
      Relaton::Cli::Command.start ["convert", file, "-f", "asciibib"]
      expect(File.exist?(output)).to be true
      File.delete output
    end

    it "output to specifed file" do
      file = "spec/fixtures/bib_item.xml"
      output = "spec/fixtures/example.yaml"
      Relaton::Cli::Command.start ["convert", file, "-f", "yaml", "-o", output]
      expect(File.exist?(output)).to be true
      File.delete output
    end
  end

  it "use verbose mode" do
    bib = double "BibItem", to_xml: "<bibitem />"
    db = double "DB"
    expect(db).to receive(:fetch) do |arg|
      expect(arg).to eq "ISO 2146"
      bib
    end
    expect(db).to receive(:fetch).with("ISO 2146", nil, verbose: true)
    expect(Relaton::Cli).to receive(:relaton).and_return(db).twice
    Relaton::Cli.start ["fetch", "ISO 2146"]
    expect(Relaton.configuration.logs).to eq %i[info error]
    Relaton::Cli.start ["fetch", "ISO 2146", "-v"]
    expect(Relaton.configuration.logs).to eq %i[info error warning]
  end
end
