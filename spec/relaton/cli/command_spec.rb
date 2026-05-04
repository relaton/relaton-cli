RSpec.describe Relaton::Cli::Command do
  it "show relaton versions" do
    expect do
      Relaton::Cli::Command.start ["version"]
    end.to output(%r{
      CLI\s=>\s#{Relaton::Cli::VERSION}\n
      relaton\s=>\s[\w.]+\n
      relaton-bib\s=>\s[\w.]+\n
      relaton-gb\s=>\s[\w.]+\n
      relaton-iec\s=>\s[\w.]+\n
      relaton-ietf\s=>\s[\w.]+\n
      relaton-iso\s=>\s[\w.]+\n
      relaton-itu\s=>\s[\w.]+\n
      relaton-nist\s=>\s[\w.]+\n
      relaton-ogc\s=>\s[\w.]+\n
      relaton-calconnect\s=>\s[\w.]+\n
      relaton-omg\s=>\s[\w.]+\n
      relaton-un\s=>\s[\w.]+\n
      relaton-w3c\s=>\s[\w.]+\n
      relaton-ieee\s=>\s[\w.]+\n
      relaton-iho\s=>\s[\w.]+\n
      relaton-bipm\s=>\s[\w.]+\n
      relaton-ecma\s=>\s[\w.]+\n
      relaton-cie\s=>\s[\w.]+\n
      relaton-bsi\s=>\s[\w.]+\n
      relaton-cen\s=>\s[\w.]+\n
      relaton-iana\s=>\s[\w.]+\n
      relaton-3gpp\s=>\s[\w.]+\n
      relaton-oasis\s=>\s[\w.]+\n
      relaton-doi\s=>\s[\w.]+\n
      relaton-jis\s=>\s[\w.]+\n
      relaton-xsf\s=>\s[\w.]+\n
      relaton-ccsds\s=>\s[\w.]+\n
      relaton-etsi\s=>\s[\w.]+\n
      relaton-isbn\s=>\s[\w.]+\n
      relaton-plateau\s=>\s[\w.]+\n
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
    expect(Relaton.logger_pool[:default].level).to eq Logger::WARN
    Relaton::Cli.start ["fetch", "ISO 2146", "-v"]
    expect(Relaton.logger_pool[:default].level).to eq Logger::INFO
  end
end
