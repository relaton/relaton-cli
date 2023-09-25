RSpec.describe Relaton::Cli::Command do
  it "show relaton versions" do
    expect do
      Relaton::Cli::Command.start ["version"]
    end.to output(%r{
      CLI\s=>\s#{Relaton::Cli::VERSION}\n
      relaton\s=>\s#{Relaton::VERSION}\n
      relaton-bib\s=>\s[\d.]+\n
      relaton-iso-bib\s=>\s[\d.]+\n
      relaton-gb\s=>\s[\d.]+\n
      relaton-iec\s=>\s[\d.]+\n
      relaton-ietf\s=>\s[\d.]+\n
      relaton-iso\s=>\s[\d.]+\n
      relaton-itu\s=>\s[\d.]+\n
      relaton-nist\s=>\s[\d.]+\n
      relaton-ogc\s=>\s[\d.]+\n
      relaton-calconnect\s=>\s[\d.]+\n
      relaton-omg\s=>\s[\d.]+\n
      relaton-un\s=>\s[\d.]+\n
      relaton-w3c\s=>\s[\d.]+\n
      relaton-ieee\s=>\s[\d.]+\n
      relaton-iho\s=>\s[\d.]+\n
      relaton-bipm\s=>\s[\d.]+\n
      relaton-ecma\s=>\s[\d.]+\n
      relaton-cie\s=>\s[\d.]+\n
      relaton-bsi\s=>\s[\d.]+\n
      relaton-cen\s=>\s[\d.]+\n
      relaton-iana\s=>\s[\d.]+\n
      relaton-3gpp\s=>\s[\d.]+\n
      relaton-oasis\s=>\s[\d.]+\n
      relaton-doi\s=>\s[\d.]+\n
      relaton-jis\s=>\s[\d.]+\n
      relaton-xsf\s=>\s[\d.]+\n
    }xo).to_stdout
  end

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
    expect(Relaton.configuration.logger.level).to eq Logger::WARN
    Relaton::Cli.start ["fetch", "ISO 2146", "-v"]
    expect(Relaton.configuration.logger.level).to eq Logger::INFO
  end
end
