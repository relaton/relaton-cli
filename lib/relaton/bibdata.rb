
module Relaton
  class Bibdata
    ATTRIBS = %i[
      docid
      doctype
      title
      stage
      relation
      uri
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
      ret += "<uri>#{uri}</uri>\n"
      ret += "<docidentifier>#{docid}</docidentifier>\n"
      ret += "<date type='#{datetype}'><on>#{revdate}</on></date>\n" if revdate
      ret += "<abstract>#{abstract}</abstract>\n" if abstract
      ret += "<status>#{stage}</status>\n" if stage
      ret += "<technical-committee>#{technical_committee}</technical-committee>\n" if technical_committee
      ret += "</bibdata>\n"
    end

  end
end
