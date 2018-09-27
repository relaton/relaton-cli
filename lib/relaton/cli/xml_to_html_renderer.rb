
module Relaton::Cli
  class XmlToHtmlRenderer

    # require "byebug"; byebug
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

    def script_cdata(result)
      result.gsub(%r{<script>\s*<!\[CDATA\[}m, "<script>").
        gsub(%r{\]\]>\s*</script>}, "</script>").
        gsub(%r{<!\[CDATA\[\s*<script>}m, "<script>").
        gsub(%r{</script>\s*\]\]>}, "</script>")
    end

    def render(file_content, css_path, relaton_root)
      doc = Nokogiri::XML(file_content)
      stylesheet = File.read(css_path)

      result = noko do |xml|
        xml.html do |html|
          define_head(
            html,
            stylesheet,
            doc&.at(ns("./relaton-collection/title"))&.text || "Untitled"
          )
          make_body html, doc, relaton_root
        end
      end.join("\n")

      script_cdata(result)
    end

    def define_head(html, stylesheet, title)
      html.head do |head|
        head.title { |t| t << title }
        head.style do |style|
          style.comment "\n#{stylesheet}\n"
        end
        head.meta **{ "http-equiv": "Content-Type", content: "text/html", charset: "utf-8" }

        [
          "https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js",
          "https://cdn.rawgit.com/jgallen23/toc/0.3.2/dist/toc.min.js"
        ].each do |url|
          head.script **{ src: url, type: "text/javascript" } do |s|
            s.text nil
          end
        end

        [
          {
            href: "https://fonts.googleapis.com/css?family=Open+Sans:300,300i,400,400i,600,600i|Space+Mono:400,700|Overpass:300,300i,600,900|Ek+Mukta:200",
            rel: "stylesheet",
            type: "text/css"
          },
          {
            href: "https://use.fontawesome.com/releases/v5.0.8/css/solid.css",
            integrity: "sha384-v2Tw72dyUXeU3y4aM2Y0tBJQkGfplr39mxZqlTBDUZAb9BGoC40+rdFCG0m10lXk",
            crossorigin: "anonymous"
          },
          {
            href: "https://use.fontawesome.com/releases/v5.0.8/css/fontawesome.css",
            integrity: "sha384-q3jl8XQu1OpdLgGFvNRnPdj5VIlCvgsDQTQB6owSOHWlAurxul7f+JpUOVdAiJ5P",
            crossorigin: "anonymous"
          }

        ].each do |attribs|
          head.link **attribs
        end

      end
    end

    def make_body(html, xml, relaton_root)
      # require "byebug"; byebug
      body_attr = { lang: "EN-US", link: "blue", vlink: "#954F72" }
      html.body **body_attr do |body|
        make_body1(body, xml)
        make_body2(body, xml)
        make_body3(body, xml, relaton_root)
        scripts(body)
      end
    end

    def make_body1(body, docxml)
      body.div **{ class: "title-section" } do |div1|
        div1 << <<~END
      <header>
        <div class="coverpage">
          <div class="wrapper-top">
            <div class="coverpage-doc-identity">
              <div class="coverpage-title">
                <span class="title-first">#{docxml&.at(ns("./relaton-collection/title"))&.text}</span>
              </div>
            </div>
          </div>
        <div>
      </header>
        END
      end
    end

    def make_body2(body, docxml)
      body.div **{ class: "prefatory-section" } do |div2|
        div2.p { |p| p << "&nbsp;" } # placeholder
      end
    end

    def make_body3(body, docxml, relaton_root)
      # require "byebug"; byebug
      body.main **{ class: "main-section" } do |div3|
        docxml.xpath(ns("./relaton-collection/relation")).each do |x|
          iterate(div3, x.at(ns("./bibdata | ./relaton-collection")), 2, relaton_root)
        end
      end

      body.div **{ class: "copyright" } do |div1|
        div1 << <<~END
          <p class="year">
            © The Calendaring and Scheduling Consortium, Inc.
          </p>
          <p class="message">
            All rights reserved. Unless otherwise specified, no part of this publication may be reproduced or utilized otherwise in any form or by any means, electronic or mechanical, including photocopying, or posting on the internet or an intranet, without prior written permission. Permission can be requested from the address below.
          </p>
        END
      end

    end

    def script
      <<~"END"
    <script>
      $(document).ready(function() {
        $('[id^=toc]').each(function () {
           var currentToc = $(this);
           var url = window.location.href;
           currentToc.wrap("<a href='" + url + "#" + currentToc.attr("id") + "' <\/a>");
        });
      });
      anchors.options = { placement: 'left' };
      anchors.add('h1, h2, h3, h4');
    </script>
      END
    end

    def scripts(body)
      body.parent.add_child script
    end

    EXTENSION_TYPES = [
      {
        text: "HTML",
        extension: ".html"
      },
      {
        text: "PDF",
        extension: ".pdf"
      },
      {
        text: "Word",
        extension: ".doc"
      },
      {
        text: "XML",
        extension: ".xml"
      }
    ]

    def uri_for_extension(uri, extension)
      uri.sub(/\.[^.]+$/, extension.to_s)
    end

    def iterate(d0, bib, depth, relaton_root)
      # require "byebug"; byebug
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
