RSpec.describe "Relaton Concatenate" do
  describe "relaton concatenate" do
    it "sends concatenate message to the concatenator" do
      allow(Relaton::Cli::RelatonFile).to receive(:concatenate)
      command = %w(concatenate spec/fixtures ./tmp/concatenate.rxl -t Title)

      Relaton::Cli.start(command)

      expect(Relaton::Cli::RelatonFile).to have_received(:concatenate).
        with("spec/fixtures", "./tmp/concatenate.rxl", title: "Title", extension: "rxl")
    end
  end
end
