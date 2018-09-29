require "nokogiri"
require "liquid"
require 'pp'

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

    COPYRIGHT = "All rights reserved. Unless otherwise specified, no part of this publication may be reproduced or utilized otherwise in any form or by any means, electronic or mechanical, including photocopying, or posting on the internet or an intranet, without prior written permission."

    def hash_to_liquid(hash)
      hash.map { |k, v| [k.to_s, empty2nil(v)] }.to_h
    end

    def render(file_content, css_path, relaton_root, html_template)
      source = Nokogiri::XML(file_content)
      stylesheet = File.read(css_path, encoding: "utf-8")

      Liquid::Template.file_system = Liquid::LocalFileSystem.new(__dir__)
      template = File.read(html_template || "#{__dir__}/template.liquid", encoding: "utf-8")

      # iterate(div, x.at(ns("./bibdata | ./relaton-collection")), 2, relaton_root)
      bibcollection = ::Relaton::Bibcollection.from_xml(source)

      puts "@"*38
      puts bibcollection.inspect
      puts "@"*38

      locals = {
        css: stylesheet,
        title: bibcollection.title,
        author: bibcollection.author,
        documents: bibcollection.to_h[:items].map { |i| hash_to_liquid(i) },
        copyright: COPYRIGHT,
        depth: 2
      }

      # puts "template: #{template}"
      puts "B"*30
      puts "#{bibcollection.inspect}"
      puts "B"*30
      #ret = liquid(template).render(params.map { |k, v| [k.to_s, empty2nil(v)] }.to_h)
      puts "#{bibcollection.items.size}"

      pp bibcollection.to_h[:items]

      puts "B"*30
      ret = Liquid::Template.parse(template).render(hash_to_liquid(locals))
      ret
    end

    def uri_for_extension(uri, extension)
      return nil if uri.nil?
      uri.sub(/\.[^.]+$/, ".#{extension.to_s}")
    end

    def iterate(d0, bib, depth, relaton_root)
      # id_code = id.downcase.gsub(/[\s\/]/, "-") unless id.nil?

      # bib.relaton_xml_path = URI.escape("#{relaton_root}/#{id_code}.xml")

      # bib.xpath(ns("./relation")).each do |x|
      #   iterate(d, x.at(ns("./bibdata | ./relaton-collection")), depth + 1, relaton_root)
      # end
    end

  end
end
