describe Relaton::Util do
  it "#respond_to_missing?" do
    expect(described_class.respond_to?(:warn)).to be true
  end
end
