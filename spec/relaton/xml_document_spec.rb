require "spec_helper"

RSpec.describe Relaton::XmlDocument do
  describe ".parse" do
    it "parse an xml document attributes" do
      document = Relaton::XmlDocument.parse(
        File.read("spec/fixtures/relaton.xml"),
      )

      expect(document[:title]).to eq("Title")
      expect(document[:stage]).to eq("STAGE")
      expect(document[:script]).to eq("SCRIPT")
      expect(document[:doctype]).to eq("standard")
      expect(document[:edition]).to eq("EDITION")
      expect(document[:abstract]).to eq("ABSTRACT")
      expect(document[:language]).to eq("LANGUAGE")
      expect(document[:uri]).to eq("URI")
      expect(document[:rxl]).to eq("RXL")
      expect(document[:xml]).to eq("XML")
      expect(document[:pdf]).to eq("PDF")
      expect(document[:doc]).to eq("DOC")
      expect(document[:html]).to eq("HTML")
      expect(document[:docidentifier]).to eq("ID")
      expect(document[:datetype]).to eq("published")
      expect(document[:revdate]).to eq("1000-01-01")
      expect(document[:copyright_from]).to eq("1900")
      expect(document[:copyright_owner]).to eq("DISNEY")
      expect(document[:technical_committee]).to eq("TC")
      expect(document[:contributor_author_role]).to eq("AUTHOR_ROLE")
      expect(document[:contributor_author_organization]).to eq("AUTHORG")
      expect(document[:contributor_publisher_organization]).to eq("PUBLISHERG")
    end
  end

  def relaton_xml
    @relaton_xml ||= File.read("spec/fixtures/relaton.xml")
  end
end
