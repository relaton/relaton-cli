require "relaton/element_finder"

module Relaton
  class Bibcollection
    extend Relaton::ElementFinder

    ATTRIBS = %i[title items doctype author].freeze

    attr_accessor *ATTRIBS

    def initialize(options) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      ATTRIBS.each do |k|
        value = options[k] || options[k.to_s]
        send("#{k}=", value)
      end
      self.items = (items || []).reduce([]) do |acc, item|
        acc << if item.is_a?(Bibcollection) || item.is_a?(Bibdata)
                 item
               else new_bib_item_class(item)
               end
      end
    end

    # arbitrary number, must sort after all bib items
    def doc_number
      9999999
    end

    # rubocop:disable Metrics/MethodLength

    # @param source [Nokogiri::XML::Element]
    def self.from_xml(source)
      title = find_text("./relaton-collection/title", source)
      author = find_text(
        "./relaton-collection/contributor[role/@type='author']/organization/"\
        "name", source
      )

      items = find_xpath("./relaton-collection/relation", source)&.map do |item|
        bibdata = find("./bibdata|./bibitem", item)
        klass = bibdata ? Bibdata : Bibcollection
        klass.from_xml(bibdata || item)
      end

      new(title: title, author: author, items: items)
    end
    # rubocop:enable Metrics/MethodLength

    def new_bib_item_class(options)
      if options.is_a?(Hash)
        if options["items"]
          ::Relaton::Bibcollection.new(options)
        else ::Relaton::Cli::YAMLConvertor.convert_single_file options
        end
      else ::Relaton::Bibdata.new(options)
      end
    end

    def items_flattened
      items.sort_by! &:docnumber

      items.reduce([]) do |acc, item|
        acc << if item.is_a? ::Relaton::Bibcollection
                 item.items_flattened
               else
                 item
               end
      end
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength

    # @param opts [Hash]
    # @return [String] XML
    def to_xml(opts = {})
      items.sort_by! &:doc_number

      collection_type = if doctype
                          "type=\"#{doctype}\""
                        else
                          'xmlns="https://open.ribose.com/relaton-xml"'
                        end

      ret = "<relaton-collection #{collection_type}>"
      ret += "<title>#{title}</title>" if title
      if author
        ret += "<contributor><role type='author'/><organization><name>"\
        "#{author}</name></organization></contributor>"
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
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def to_yaml
      to_h.to_yaml
    end

    def to_h
      items.sort_by! &:doc_number

      a = ATTRIBS.reduce({}) do |acc, k|
        acc[k.to_s] = send(k)
        acc
      end

      a["items"] = a["items"].map(&:to_h)

      { "root" => a }
    end
  end
end
