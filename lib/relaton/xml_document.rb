require "relaton/element_finder"

module Relaton
  class XmlDocument
    include Relaton::ElementFinder

    def initialize(document)
      @document = nokogiri_document(document) || document
    end

    def parse
      base_attributes.merge(complex_attributes)
    end

    def self.parse(document)
      new(document).parse
    end

    private

    attr_reader :document

    def nokogiri_document(document)
      if document.class == String
        Nokogiri::XML(document)&.root
      end
    end

    def base_attributes
      Hash.new.tap do |attributes|
        elements.each {|key, xpath| attributes[key] = find_text(xpath) }
      end
    end

    def complex_attributes
      (date_attributes || {}).merge(
        contributor_author_organization: find_organization_for('author'),
        contributor_publisher_organization: find_organization_for('publisher'),
      )
    end

    def find_organization_for(type)
      find("./contributor/role[@type='#{type}']")&.parent&.
        at(apply_namespace("./organization/name"))&.text
    end

    def elements
      {
        title: "./title",
        stage: "./status",
        script: "./script",
        doctype: "./@type",
        edition: "./edition",
        abstract: "./abstract",
        language: "./language",
        uri: "./uri[not(@type)]",
        rxl: "./uri[@type='rxl']",
        xml: "./uri[@type='xml']",
        pdf: "./uri[@type='pdf']",
        doc: "./uri[@type='doc']",
        html: "./uri[@type='html']",
        docidentifier: "./docidentifier",
        copyright_from: "./copyright/from",
        copyright_owner: "./copyright/owner/organization/name",
        technical_committee: "./editorialgroup/technical-committee",
        contributor_author_role: "./contributor/role[@type='author']",
        contributor_publisher_role: "./contributor/role[@type='publisher']",
      }
    end

    def date_attributes
      revdate =
        find("./date[@type = 'published']") ||
        find("./date[@type = 'circulated']") ||
        find("./date")

      value = find_text("./on", revdate) || find_text("./form", revdate)

      if revdate && value
        { datetype: revdate["type"], revdate: Date.parse(value.strip).to_s }
      end
    rescue
      warn "[relaton] parsing published date '#{revdate.text}' failed."
      { datetype: "circulated", revdate: value.strip }
    end
  end
end
