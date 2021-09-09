RSpec.describe "Relaton fetch-data" do
  it "send fetch-data message to DataFetcher" do
    Relaton::Registry.instance
    expect(RelatonNist::DataFetcher).to receive(:fetch)
      .with output: "dir", format: "xml"
    command = %w[fetch-data nist-tech-pubs -o dir -f xml]
    Relaton::Cli.start command
  end

  it "send cie-techstreet message to DataFetcher" do
    Relaton::Registry.instance
    expect(RelatonCie::DataFetcher).to receive(:fetch)
      .with output: "dir", format: "xml"
    command = %w[fetch-data cie-techstreet -o dir -f xml]
    Relaton::Cli.start command
  end

  it "send calconnect-org message to DataFetcher" do
    Relaton::Registry.instance
    expect(RelatonCalconnect::DataFetcher).to receive(:fetch)
      .with output: "dir", format: "xml"
    command = %w[fetch-data calconnect-org -o dir -f xml]
    Relaton::Cli.start command
  end
end
