require "relaton/element_finder"

module Relaton
  class BibcollectionNew
    extend Relaton::ElementFinder

    ATTRIBS = %i[
      title
      items
      doctype
      author
    ]

    attr_accessor *ATTRIBS

    def initialize(options)
      self.items = []
      ATTRIBS.each do |k|
        value = options[k] || options[k.to_s]
        self.send("#{k}=", value)
      end
      self.items = (self.items || []).inject([]) do |acc,item|
        acc << if item.is_a?(::Relaton::BibcollectionNew) ||
          item.is_a?(::RelatonBib::BibliographicItem)
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
      title = find_text("./relaton-collection/title", source)
      author = find_text("./relaton-collection/contributor[role/@type = 'author']/organization/name", source)

      items = find_xpath("./relaton-collection/relation", source)&.map do |item|
        bibdata = find("./bibdata", item)
        klass = bibdata ? Bibdata : BibcollectionNew
        klass.from_xml(bibdata || item)
      end

      new(title: title, author: author, items: items)
    end

    def new_bib_item_class(options)
      if options["items"]
        ::Relaton::BibcollectionNew.new(options)
      else
        ::RelatonBib::BibliographicItem.new(options)
      end
    end

    def items_flattened
      items.sort_by! do |b|
        b.doc_number
      end

      items.inject([]) do |acc,item|
        if item.is_a? ::Relaton::BibcollectionNew
          acc << item.items_flattened
        else
          acc << item
        end
      end
    end

    def to_xml(opts)
      items.sort_by! do |b|
        b.docnumber
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
          ret += item.to_xml(opts)
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
