
module Relaton
  class Bibcollection
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
        method = "#{k}="
        value = options[k.to_s]
        # puts "K #{method}"
        # puts value.inspect

        self.send("#{k}=", options[k.to_s])
        # puts "SET! to #{self.send(k).inspect}"
      end

      # puts items.inspect
      self.items = self.items.inject([]) do |acc,item|
        acc << if item.is_a?(::Relaton::Bibcollection) ||
          item.is_a?(::Relaton::Bibdata)

          item
        else
          # puts "item.inspect #{item.inspect}"
          new_bib_item_class(item)
        end
      end

      self
      # byebug
    end

    def new_bib_item_class(options)
      if options["items"]
        ::Relaton::Bibcollection.new(options)
      else
        ::Relaton::Bibdata.new(options)
      end
    end

    def items_flattened

      items.inject([]) do |acc,item|
        if item.is_a? ::Relaton::Bibcollection
          acc << item.items_flattened
        else
          acc << item
        end
      end

    end

    def to_xml
      collection_type = if doctype
        "type=\"#{doctype}\""
      else
        'xmlns="http://riboseinc.com/isoxml"'
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

  end
end
