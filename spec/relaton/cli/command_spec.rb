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
end
