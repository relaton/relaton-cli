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
  <docidentifier>CS 3</docidentifier>
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
  <relation>
  <bibdata>
  <title>Bibdata 4</title>
  <docidentifier>CS</docidentifier>
  </bibdata>
  </relation>
  <relation>
  <bibdata>
  <title>Bibdata 3</title>
  <docidentifier>CS 2</docidentifier>
  </bibdata>
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
    expect(collection.to_xml).to be_equivalent_to <<~"XML"
<relaton-collection xmlns="https://open.ribose.com/relaton-xml"><title>Title</title><contributor><role type='author'/><organization><name>Orgname1</name></organization></contributor><relation type='partOf'><bibdata type=''>
       <fetched>#{Date.today}</fetched>
       <title>Bibdata 3</title>
       <docidentifier>CS 2</docidentifier>
       <language></language>
       <script></script>
       </bibdata>
       </relation>
       <relation type='partOf'><bibdata type=''>
       <fetched>#{Date.today}</fetched>
       <title>Bibdata 1</title>
       <docidentifier>CS 3</docidentifier>
       <language></language>
       <script></script>
       </bibdata>
       </relation>
       <relation type='partOf'><bibdata type=''>
       <fetched>#{Date.today}</fetched>
       <title>Bibdata 4</title>
       <docidentifier>CS</docidentifier>
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

RSpec.describe Relaton::Bibdata do
  it "sanitises doc identifier" do
    expect(Relaton::Bibdata.new(docidentifier: %{A/B\\C?D%E*F:G|H"I<J>K.L M/N}).docidentifier_code).to eq "a-b-c-d-e-f-g-h-i-j-k-l-m-n"
  end

  it "parses relaton XML, published document" do
    doc = <<~"XML"
<bibdata xmlns="https://open.ribose.com/relaton-xml" type="TYPE">
<title>Title</title>
<docidentifier>ID</docidentifier>
<date type="fred">1002-01-01</date>
<date type="published">1000-01-01</date>
<uri type="html">HTML</uri>
<uri type="xml">XML</uri>
<uri>URI</uri>
<uri type="pdf">PDF</uri>
<uri type="doc">DOC</uri>
<uri type="rxl">RXL</uri>
<status>STAGE</status>
<abstract>ABSTRACT</abstract>
<language>LANGUAGE</language>
<script>SCRIPT</script>
<edition>EDITION</edition>
<editorialgroup><technical-committee>TC</technical-committee></editorialgroup>
<copyright>
<from>1900</from>
<owner><organization><name>DISNEY</name></organization></owner>
</copyright>
<contributor><role type="author">AUTHOR_ROLE</role>
<organization><name>AUTHORG</name></organization></contributor>
<contributor><role type="publisher"/>
<organization><name>PUBLISHERG</name></organization></contributor>
</bibdata>
    XML
    xml = Nokogiri.XML(doc)
    bibdata = Relaton::Bibdata.from_xml(xml.root)
    expect(bibdata.title).to eq "Title"
    expect(bibdata.docidentifier).to eq "ID"
    expect(bibdata.revdate.to_s).to eq "1000-01-01"
    expect(bibdata.uri).to eq "URI"
    expect(bibdata.html).to eq "HTML"
    expect(bibdata.xml).to eq "XML"
    expect(bibdata.pdf).to eq "PDF"
    expect(bibdata.doc).to eq "DOC"
    expect(bibdata.rxl).to eq "RXL"
    expect(bibdata.doctype).to eq "TYPE"
    expect(bibdata.stage).to eq "STAGE"
    expect(bibdata.abstract).to eq "ABSTRACT"
    expect(bibdata.technical_committee).to eq "TC"
    expect(bibdata.language).to eq "LANGUAGE"
    expect(bibdata.script).to eq "SCRIPT"
    expect(bibdata.edition).to eq "EDITION"
    expect(bibdata.copyright_from).to eq "1900"
    expect(bibdata.copyright_owner).to eq "DISNEY"
    expect(bibdata.contributor_author_organization).to eq "AUTHORG"
    expect(bibdata.contributor_publisher_organization).to eq "PUBLISHERG"
    expect(bibdata.datetype).to eq "published"
    expect(bibdata.to_xml).to be_equivalent_to <<~"XML"
    <bibdata type='TYPE'>
<fetched>#{Date.today}</fetched>
<title>Title</title>
<docidentifier>ID</docidentifier>
<uri>URI</uri>
<uri type='xml'>XML</uri>
<uri type='html'>HTML</uri>
<uri type='pdf'>PDF</uri>
<uri type='doc'>DOC</uri>
<uri type='rxl'>RXL</uri>
<language>LANGUAGE</language>
<script>SCRIPT</script>
<copyright><from>1900</from>
<owner><organization><name>DISNEY</name></organization></owner>
</copyright><contributor>
<role type='author'/>
<organization><name>AUTHORG</name></organization>
</contributor>
<contributor>
<role type='publisher'/>
<organization><name>PUBLISHERG</name></organization>
</contributor>
<date type='published'><on>1000-01-01</on></date>
<edition>EDITION</edition>
<language>LANGUAGE</language>
<script>SCRIPT</script>
<abstract>ABSTRACT</abstract>
<status>STAGE</status>
<editorialgroup><technical-committee>TC</technical-committee></editorialgroup>
</bibdata>

XML
  end

    it "parses relaton XML, unpublished document" do
    doc = <<~"XML"
<bibdata xmlns="https://open.ribose.com/relaton-xml" type="TYPE">
<title>Title</title>
<date type="fred">1000-01-01</date>
<date type="circulated">1001-01-01</date>
</bibdata>
    XML
    xml = Nokogiri.XML(doc)
    bibdata = Relaton::Bibdata.from_xml(xml.root)
    expect(bibdata.title).to eq "Title"
    expect(bibdata.revdate.to_s).to eq "1001-01-01"
    expect(bibdata.datetype).to eq "circulated"
    expect(bibdata.to_xml).to be_equivalent_to <<~"XML"
<bibdata type='TYPE'>
<fetched>#{Date.today}</fetched>
<title>Title</title>
<language></language>
<script></script>
<date type='circulated'><on>1001-01-01</on></date>
</bibdata>

    XML
    end

end
