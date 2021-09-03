RSpec.describe "Relaton fetch-data" do
  it "send fetch-data message to DataFetcher" do
    Relaton::Registry.instance
    expect(RelatonNist::DataFetcher).to receive(:fetch)
      .with output: "dir", format: "xml"
    command = %w[fetch-data nist-tech-pubs -o dir -f xml]
    Relaton::Cli.start command
  end
end
