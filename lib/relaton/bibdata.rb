
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

    def initialize(options)
      options.each_pair do |k,v|
        send("#{k.to_s}=", v)
      end
    end

    def docid_code
      docid.downcase.gsub(/[\s\/]/, "-") || ""
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

  end
end
