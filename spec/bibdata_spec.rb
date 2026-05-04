RSpec.describe Relaton::Bibdata do
  subject do
    docid = Relaton::Bib::Docidentifier.new content: %{A/B\\C?D%E*F:G|H"I<J>K.L M/N}
    item = Relaton::Bib::ItemData.new docidentifier: [docid]
    Relaton::Bibdata.new(item)
  end

  it "sanitises doc identifier" do
    expect(subject.docidentifier_code).to eq "a-b-c-d-e-f-g-h-i-j-k-l-m-n"
  end

  it "calls bibitem's methods" do
    expect { subject.statuses }.to raise_error NoMethodError
  end
end
