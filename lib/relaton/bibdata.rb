
module Relaton
  class Bibdata
    ATTRIBS = %i[
      docid
      doctype
      title
      stage
      relation
      xml
      pdf
      doc
      html
      uri
      relaton
      revdate
      abstract
      technical_committee
    ]

    attr_accessor *ATTRIBS

    def self.ns(xpath)
      xpath.gsub(%r{/([a-zA-z])}, "/xmlns:\\1").
        gsub(%r{::([a-zA-z])}, "::xmlns:\\1").
        gsub(%r{\[([a-zA-z][a-z0-9A-Z@/]* ?=)}, "[xmlns:\\1").
        gsub(%r{\[([a-zA-z][a-z0-9A-Z@/]*\])}, "[xmlns:\\1")
    end

    def initialize(options)
      options.each_pair do |k,v|
        send("#{k.to_s}=", v)
      end

      puts "*+"*30
      puts self.inspect

      self
    end

    def docid_code
      docid.downcase.gsub(/[\s\/]/, "-") || ""
    end

    def self.from_xml(source)

      # bib.relaton_xml_path = URI.escape("#{relaton_root}/#{id_code}.xml")

      datetype = source.at(ns("./date[@type]")).text
      revdate = source.at(ns("./date/on")).text

      new({
        uri: source.at(ns("./uri"))&.text,
        xml: source.at(ns("./uri[@type='xml']"))&.text,
        pdf: source.at(ns("./uri[@type='pdf']"))&.text,
        html: source.at(ns("./uri[@type='html']"))&.text,
        relaton: source.at(ns("./uri[@type='relaton']"))&.text,
        doc: source.at(ns("./uri[@type='doc']"))&.text,
        docid: source.at(ns("./docidentifier"))&.text,
        title: source.at(ns("./title"))&.text,
        doctype: source.at(ns("./@type"))&.text,
        stage: source.at(ns("./status"))&.text,
        technical_committee: source.at(ns("./technical-committee"))&.text,
        abstract: source.at(ns("./abstract"))&.text,
        revdate: Date.parse(revdate)
        # revdate TODO
      })
    end

    def to_xml
      datetype = stage.casecmp("published") == 0 ? "published" : "updated"

      ret = "<bibdata type='#{doctype}'>\n"
      ret += "<title>#{title}</title>\n"
      ret += "<uri>#{uri}</uri>\n" if uri
      ret += "<uri type='xml'>#{xml}</uri>\n" if xml
      ret += "<uri type='html'>#{html}</uri>\n" if html
      ret += "<uri type='pdf'>#{pdf}</uri>\n" if pdf
      ret += "<uri type='doc'>#{doc}</uri>\n" if doc
      ret += "<uri type='relaton'>#{relaton}</uri>\n" if relaton
      ret += "<docidentifier>#{docid}</docidentifier>\n"
      ret += "<date type='#{datetype}'><on>#{revdate}</on></date>\n" if revdate
      ret += "<abstract>#{abstract}</abstract>\n" if abstract
      ret += "<status>#{stage}</status>\n" if stage
      ret += "<technical-committee>#{technical_committee}</technical-committee>\n" if technical_committee
      ret += "</bibdata>\n"
    end

    def to_h
      ATTRIBS.inject({}) do |acc, k|
        acc[k] = send(k)
        acc
      end
    end

  end
end
