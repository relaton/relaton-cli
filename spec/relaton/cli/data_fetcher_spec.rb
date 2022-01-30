RSpec.describe Relaton::Cli::DataFetcher do
  it "send ftech_data to processor" do
    src = "nist-tech-pubs"
    processor = Relaton::Registry.instance.find_processor_by_dataset src
    opts = { output: "dir", format: "xml" }
    expect(processor).to receive(:fetch_data).with src, opts
    Relaton::Cli::DataFetcher.fetch src, output: "dir", format: "xml"
  end
end
