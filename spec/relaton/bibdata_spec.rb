require "spec_helper"

RSpec.describe Relaton::Bibdata do
  describe ".from_xml" do
    context "valid document data" do
      it "parse document attributes properly" do
        bibdata = Relaton::Bibdata.from_xml(relaton_xml)

        expect(bibdata.title).to eq "Title"
        expect(bibdata.docidentifier).to eq "ID"
        expect(bibdata.revdate).to eq "1000-01-01"
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
      end
    end
  end

  def relaton_xml
    @relaton_xml ||= File.read("spec/fixtures/relaton.xml")
  end
end
