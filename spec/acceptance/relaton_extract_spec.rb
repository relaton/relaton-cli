RSpec.describe "Relaton Extract" do
  describe "relaton extract" do
    it "sends extract message to the extractor" do
      allow(Relaton::Cli::RelatonFile).to receive(:extract)
      command = %w(extract spec/fixtures ./tmp -x rxml)

      Relaton::Cli.start(command)

      expect(Relaton::Cli::RelatonFile).to have_received(:extract).
        with("spec/fixtures", "./tmp", extension: "rxml")
    end
  end
end
