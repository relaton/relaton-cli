require "spec_helper"

RSpec.describe "Relaton Split" do
  describe "relaton split"  do
    it "sends the split message relaton file" do
      allow(Relaton::Cli::RelatonFile).to receive(:split)
      command = %w(split spec/fixtures/sample-collection.xml ./tmp -x xml)

      Relaton::Cli.start(command)

      expect(Relaton::Cli::RelatonFile).to have_received(:split).
        with("spec/fixtures/sample-collection.xml", "./tmp", extension: "xml")
    end

    it "sends the split message relaton file in the new Relaton format" do
      allow(Relaton::Cli::RelatonFile).to receive(:split)
      command = %w(split spec/fixtures/sample-collection.xml ./tmp -n)

      Relaton::Cli.start(command)

      expect(Relaton::Cli::RelatonFile).to have_received(:split).
        with("spec/fixtures/sample-collection.xml", "./tmp", new: true)
    end
  end
end
