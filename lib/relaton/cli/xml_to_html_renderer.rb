require "liquid"

module Relaton::Cli
  class XmlToHtmlRenderer

    def ns(xpath)
      xpath.gsub(%r{/([a-zA-z])}, "/xmlns:\\1").
        gsub(%r{::([a-zA-z])}, "::xmlns:\\1").
        gsub(%r{\[([a-zA-z][a-z0-9A-Z@/]* ?=)}, "[xmlns:\\1").
        gsub(%r{\[([a-zA-z][a-z0-9A-Z@/]*\])}, "[xmlns:\\1")
    end

    NOKOHEAD = <<~HERE.freeze
    <!DOCTYPE html SYSTEM "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head></head>
    <body></body>
    </html>
    HERE

    # block for processing XML document fragments as XHTML,
    # to allow for HTMLentities
    def noko(&block)
      doc = ::Nokogiri::XML.parse(NOKOHEAD)
      fragment = doc.fragment("")
      ::Nokogiri::XML::Builder.with fragment, &block
      fragment.to_xml(encoding: "US-ASCII").lines.map do |l|
        l.gsub(/\s*\n/, "")
      end
    end

    def liquid(doc)
      # unescape HTML escapes in doc
      doc = doc.split(%r<(\{%|\}%)>).each_slice(4).map do |a|
        a[2].gsub!("&lt;", "<").gsub!("&gt;", ">") if a.size > 2
        a.join("")
      end.join("")
      Liquid::Template.parse(doc)
    end

    def empty2nil(v)
      return nil if !v.nil? && v.is_a?(String) && v.empty?
      v
    end

    def render(file_content, css_path, relaton_root, html_template)
      source = Nokogiri::XML(file_content)
      stylesheet = File.read(css_path, encoding: "utf-8")
      template = File.read(html_template || "#{__dir__}/template.html", encoding: "utf-8")
      div = noko do |xml|
        xml.div do |div|
          source.xpath(ns("./relaton-collection/relation")).each do |x|
            iterate(div, x.at(ns("./bibdata | ./relaton-collection")), 2, relaton_root)
          end
        end
      end.join("\n")
      params = {
        css: stylesheet,
        title: source&.at(ns("./relaton-collection/title"))&.text || "Untitled",
        author: source&.at(ns("./relaton-collection/contributor[role/@type = 'author']/organization/name"))&.text,
        content: div,
      }
      ret = liquid(template).render(params.map { |k, v| [k.to_s, empty2nil(v)] }.to_h)
      ret
    end

    EXTENSION_TYPES = [
      {
        text: "HTML",
        extension: "html"
      },
      {
        text: "PDF",
        extension: "pdf"
      },
      {
        text: "Word",
        extension: "doc"
      },
      {
        text: "XML",
        extension: "xml"
      }
    ]

    def uri_for_extension(uri, extension)
      uri.sub(/\.[^.]+$/, ".#{extension.to_s}")
    end

    def iterate(d0, bib, depth, relaton_root)
      uri = bib.at(ns("./uri"))&.text
      id = bib.at(ns("./docidentifier"))&.text
      id_code = id.downcase.gsub(/[\s\/]/, "-") unless id.nil?
      title = bib.at(ns("./title"))&.text

      d0.div **{ class: bib.name == "bibdata" ? "document" : "doc-section" } do |d|
        d.div **{ class: "doc-line" } do |d1|

          d1.div **{ class: "doc-identifier" } do |d2|
            d2.send "h#{depth}" do |h|
              if uri
                h.a **{ href: uri_for_extension(uri, :html) } do |a|
                  a << id
                end
              else
                h << id
              end
            end
          end

          d1.div **{ class: "doc-type-wrap" } do |d2|
            d2.div bib.at(ns("./@type"))&.text, **{ class: "doc-type #{bib.at(ns("./@type"))&.text&.downcase}" }
          end
        end

        d.div **{ class: "doc-title" } do |d1|
          d1.send "h#{depth+1}" do |h|

            if uri
              h.a **{ href: uri_for_extension(uri, :html) } do |a|
                a << title
              end
            else
              h << title
            end
          end
        end

        d.div **{ class: "doc-info #{bib.at(ns("./status"))&.text&.downcase}" } do |d1|
          d1.div bib.at(ns("./status"))&.text, **{ class: "doc-stage #{bib.at(ns("./status"))&.text&.downcase}" }
          d1.div **{ class: "doc-dates" } do |d2|
            if bib.at(ns("./date[@type = 'published']/on"))
              d2.div bib.at(ns("./date[@type = 'published']/on"))&.text, **{ class: "doc-published" }
            end
            if bib.at(ns("./date[@type = 'updated']/on"))
              d2.div bib.at(ns("./date[@type = 'updated']/on"))&.text, **{ class: "doc-updated" }
            end
          end
        end

        if id
          d.div **{ class: "doc-bib" } do |d1|
            d1.div **{ class: "doc-bib-relaton" } do |d2|
              d2.a **{ href: URI.escape("#{relaton_root}/#{id_code}.xml") } do |a|
                a << "Relaton XML"
              end
            end
          end
        end

        if uri
          d.div **{ class: "doc-access" } do |d1|

            EXTENSION_TYPES.each do |attribs|
              d1.div **{ class: "doc-access-button-#{attribs[:extension]}" } do |d2|
                d2.a **{ href: uri_for_extension(uri, attribs[:extension]) } do |a|
                  a << attribs[:text]
                end
              end
            end
          end
        end

        bib.xpath(ns("./relation")).each do |x|
          iterate(d, x.at(ns("./bibdata | ./relaton-collection")), depth + 1, relaton_root)
        end
      end
    end

  end
end
