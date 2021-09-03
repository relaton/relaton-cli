RSpec.describe Relaton::Cli::DataFetcher do
  it "send ftech_data to processor" do
    src = "nist-tech-pubs"
    processor = Relaton::Registry.instance.find_processor_by_dataset src
    expect(processor).to receive(:fetch_data).with src, output: "dir", format: "xml"
    Relaton::Cli::DataFetcher.fetch src, output: "dir", format: "xml"
  end
end
