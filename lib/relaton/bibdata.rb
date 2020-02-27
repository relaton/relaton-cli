require "date"

module Relaton
  class Bibdata
    URL_TYPES = %i[uri xml pdf doc html rxl txt]

    attr_reader :bibitem

    def initialize(bibitem)
      @bibitem = bibitem
    end

    # def method_missing(method, *args)
    #   %r{(?<m>\w+)=$} =~ method
    #   return unless m && %w[xml pdf doc html rxl txt].include?(m)

    #   uri = @bibitem.link.detect { |u| u.type == m }
    #   if uri
    #     uri.content = args[0]
    #   else
    #     @bibitem.link << RelatonBib::TypedUri.new(type: m, content: args[0])
    #   end
    # end

    def docidentifier
      @bibitem.docidentifier.first&.id
    end

    # def doctype
    #   @bibitem.type
    # end

    # From http://gavinmiller.io/2016/creating-a-secure-sanitization-function/
    FILENAME_BAD_CHARS = [ '/', '\\', '?', '%', '*', ':', '|', '"', '<', '>', '.', ' ' ]

    def docidentifier_code
      return "" if docidentifier.nil?
      a = FILENAME_BAD_CHARS.inject(docidentifier.downcase) do |result, bad_char|
        result.gsub(bad_char, '-')
      end
    end

    DOC_NUMBER_REGEX = /([\w\/]+)\s+(\d+):?(\d*)/
    def doc_number
      docidentifier&.match(DOC_NUMBER_REGEX) ? $2.to_i : 999999
    end

    def self.from_xml(source)
      bi = Relaton::Cli.parse_xml(source)
      new(bi) if bi
    end

    def to_xml(opts = {})
      options = { bibdata: true, date_format: :full }.merge opts.select { |k,v| k.is_a? Symbol }
      @bibitem.to_xml nil, **options

      # #datetype = stage&.casecmp("published") == 0 ? "published" : "circulated"

      # ret = ref ? "<bibitem id= '#{ref}' type='#{doctype}'>\n" : "<bibdata type='#{doctype}'>\n"
      # ret += "<fetched>#{Date.today.to_s}</fetched>\n"
    end

    def to_h
      URL_TYPES.reduce(@bibitem.to_hash) do |h, t|
        value = self.send t
        h[t.to_s] = value
        h
      end
    end

    def to_yaml
      to_h.to_yaml
    end

    def method_missing(meth, *args)
      if @bibitem.respond_to?(meth)
        @bibitem.send meth, *args
      elsif URL_TYPES.include? meth
        link = @bibitem.link.detect { |l| l.type == meth.to_s || meth == :uri && l.type.nil? }
        link&.content&.to_s
      elsif URL_TYPES.include? meth.match(/^\w+(?==)/).to_s.to_sym
        /^(?<type>\w+)/ =~ meth
        link = @bibitem.link.detect { |l| l.type == type || type == "uri" && l.type.nil? }
        if link
          link.content = args[0]
        else
          @bibitem.link << RelatonBib::TypedUri.new(type: type, content: args[0])
        end
      else
        super
      end
    end
  end
end
