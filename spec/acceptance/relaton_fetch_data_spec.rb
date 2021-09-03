RSpec.describe "Relaton fetch-data" do
  it "send fetch-data message to DataFetcher" do
    expect(Relaton::Cli::DataFetcher).to receive(:fetch)
      .with "dataset", output: "dir", format: "xml"
    command = %w[fetch-data dataset -o dir -f xml]
    Relaton::Cli.start command
  end
end
