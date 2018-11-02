
module Relaton
  class Bibcollection
    ATTRIBS = %i[
      title
      items
      doctype
      author
    ]

    attr_accessor *ATTRIBS

    def self.ns(xpath)
      xpath.gsub(%r{/([a-zA-z])}, "/xmlns:\\1").
        gsub(%r{::([a-zA-z])}, "::xmlns:\\1").
        gsub(%r{\[([a-zA-z][a-z0-9A-Z@/]* ?=)}, "[xmlns:\\1").
        gsub(%r{\[([a-zA-z][a-z0-9A-Z@/]*\])}, "[xmlns:\\1")
    end

    def initialize(options)
      self.items = []
      ATTRIBS.each do |k|
        value = options[k] || options[k.to_s]
        self.send("#{k}=", value)
      end
      self.items = (self.items || []).inject([]) do |acc,item|
        acc << if item.is_a?(::Relaton::Bibcollection) ||
          item.is_a?(::Relaton::Bibdata)
          item
        else
          new_bib_item_class(item)
        end
      end
      self
    end

    # arbitrary number, must sort after all bib items
    def doc_number
      9999999
    end

    def self.from_xml(source)
      title = source&.at(ns("./relaton-collection/title"))&.text
      author = source&.at(ns("./relaton-collection/contributor[role/@type = 'author']/organization/name"))&.text
      items = source&.xpath(ns("./relaton-collection/relation"))&.map do |item|
        klass = item.at(ns("./bibdata")) ? Bibdata : Bibcollection
        klass.from_xml(item.at(ns("./bibdata")) || item)
      end
      opts = { title: title, author: author, items: items }
      new(opts)
    end

    def new_bib_item_class(options)
      if options["items"]
        ::Relaton::Bibcollection.new(options)
      else
        ::Relaton::Bibdata.new(options)
      end
    end

    def items_flattened
      items.sort_by! do |b|
        b.doc_number
      end

      items.inject([]) do |acc,item|
        if item.is_a? ::Relaton::Bibcollection
          acc << item.items_flattened
        else
          acc << item
        end
      end
    end

    def to_xml
      items.sort_by! do |b|
        b.doc_number
      end

      collection_type = if doctype
        "type=\"#{doctype}\""
      else
        'xmlns="https://open.ribose.com/relaton-xml"'
      end

      ret = "<relaton-collection #{collection_type}>"
      ret += "<title>#{title}</title>" if title
      if author
        ret += "<contributor><role type='author'/><organization><name>#{author}</name></organization></contributor>"
      end
      unless items.empty?
        items.each do |item|
          ret += "<relation type='partOf'>"
          ret += item.to_xml
          ret += "</relation>\n"
        end
      end
      ret += "</relaton-collection>\n"
    end

    def to_yaml
      to_h.to_yaml
    end

    def to_h
      items.sort_by! do |b|
        b.doc_number
      end

      a = ATTRIBS.inject({}) do |acc, k|
        acc[k.to_s] = send(k)
        acc
      end

      a["items"] = a["items"].map(&:to_h)

      { "root" => a }
    end

  end
end
