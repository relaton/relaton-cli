RSpec.describe "Relaton fetch-data" do
  it "send fetch_data message to proceessor" do
    processor = Relaton::Cli.registry.find_processor_by_dataset "nist-tech-pubs"
    expect(processor).to receive(:fetch_data).with("nist-tech-pubs", { output: "dir", format: "xml" })
    command = %w[fetch-data nist-tech-pubs -o dir -f xml]
    Relaton::Cli.start command
  end

  # it "send cie-techstreet message to DataFetcher" do
  #   processor = Relaton::Cli.registry.find_processor_by_dataset "cie-techstreet"
  #   expect(processor).to receive(:fetch_data).with("cie-techstreet", { output: "dir", format: "xml" })
  #   command = %w[fetch-data cie-techstreet -o dir -f xml]
  #   Relaton::Cli.start command
  # end

  # it "send calconnect-org message to DataFetcher" do
  #   Relaton::Cli.registry
  #   expect(RelatonCalconnect::DataFetcher).to receive(:fetch)
  #     .with output: "dir", format: "xml"
  #   command = %w[fetch-data calconnect-org -o dir -f xml]
  #   Relaton::Cli.start command
  # end
end
