RSpec.describe "Relaton Split" do
  describe "relaton split" do
    it "sends the split message relaton file" do
      allow(Relaton::Cli::RelatonFile).to receive(:split)
      command = %w(split spec/fixtures/sample-collection.xml ./tmp -x xml)

      Relaton::Cli.start(command)

      expect(Relaton::Cli::RelatonFile).to have_received(:split).
        with("spec/fixtures/sample-collection.xml", "./tmp", extension: "xml")
    end

    it "sends the split message relaton file and write results to RXL files" do
      allow(Relaton::Cli::RelatonFile).to receive(:split)
      command = %w(split spec/fixtures/sample-collection.xml ./tmp)

      Relaton::Cli.start(command)

      expect(Relaton::Cli::RelatonFile).to have_received(:split)
        .with("spec/fixtures/sample-collection.xml", "./tmp", extension: "rxl")
    end
  end
end
