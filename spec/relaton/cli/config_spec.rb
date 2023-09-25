describe Relaton::Cli do
  after { described_class.instance_variable_set :@configuration, nil }

  it "configure" do
    described_class.configure do |conf|
      conf.logger = :logger
    end
    expect(described_class.configuration.logger).to eq :logger
  end
end
