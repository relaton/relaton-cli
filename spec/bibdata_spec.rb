require_relative "spec_helper"
require "nokogiri"

RSpec.describe Relaton::Bibcollection do
  it "parses relaton-collection XML" do
    doc = <<~"XML"
  <relaton-collection xmlns="https://open.ribose.com/relaton-xml">
  <title>Title</title>
  <contributor><role type="publisher"/><organization><name>Orgname2</name</organization></contributor>
  <contributor><role type="author"/><person><name>Orgname3</name</person></contributor>
  <contributor><role type="author"/><organization><name>Orgname1</name</organization></contributor>
  <relation>
  <bibdata>
  <title>Bibdata 1</title>
  </bibdata>
  </relation>
  <relation>
  <relaton-collection>
  <title>Title 2</title>
  <relation>
  <bibdata>
  <title>Bibdata 2</title>
  </bibdata>
  </relation>
  </relaton-collection>
  </relation>
  </relaton-collection>
    XML
    xml = Nokogiri.XML(doc)
    collection = Relaton::Bibcollection.from_xml(xml)
    expect(collection.title).to eq "Title"
    expect(collection.author).to eq "Orgname1"
    expect(collection.items[0].title).to eq "Bibdata 1"
    expect(collection.items[1].title).to eq "Title 2"
    expect(collection.items[1].items[0].title).to eq "Bibdata 2"
    require "byebug"; byebug
    expect(collection.to_xml).to be_equivalent_to <<~"XML"
    <relaton-collection xmlns="https://open.ribose.com/relaton-xml"><title>Title</title><contributor><role type='author'/><organization><name>Orgname1</name></organization></contributor><relation type='partOf'><bibdata type=''>
<fetched>#{Date.today}</fetched>
<title>Bibdata 1</title>
<language></language>
<script></script>
</bibdata>
</relation>
<relation type='partOf'><relaton-collection xmlns="https://open.ribose.com/relaton-xml"><title>Title 2</title><relation type='partOf'><bibdata type=''>
<fetched>#{Date.today}</fetched>
<title>Bibdata 2</title>
<language></language>
<script></script>
</bibdata>
</relation>
</relaton-collection>
</relation>
</relaton-collection>
    XML
  end
end


