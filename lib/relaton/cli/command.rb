require "relaton"
require "nokogiri"
require "yaml"
require "thor"
require "fileutils"
require "pathname"
require "fcntl"

require "relaton/cli/xml_convertor"
require "relaton/cli/yaml_convertor"

module Relaton
  module Cli
    class Command < Thor

      desc "fetch CODE", "Fetch Relaton XML for Standard identifier CODE"
      option :type, aliases: :t, required: true, desc: "Type of standard to get bibliographic entry for"
      option :year, aliases: :y, type: :numeric, desc: "Year the standard was published"

      def fetch(code)
        Relaton::Cli.relaton
        say(fetch_document(code, options) || supported_type_message)
      end

      desc "extract Metanorma-XML-Directory Relaton-XML-Directory", "Extract Relaton XML from folder of Metanorma XML"

      option :extension, :required => false, :desc => "File extension of Relaton XML files, defaults to 'rxl'", :aliases => :x, :default => "rxl"

      def extract(source_dir, outdir)
        Dir[ File.join(source_dir, '**', '*.xml') ].reject { |p| File.directory? p }.each do |f|
          xml = Nokogiri::XML(File.read(f, encoding: "utf-8")).remove_namespaces!
          bib = xml.at("//bibdata") || next
          bib.add_namespace(nil, "")
          docidentifier = bib&.at("./docidentifier")&.text ||
            Pathname.new(File.basename(f, ".xml")).to_s
          fn = docidentifier.sub(/^\s+/, "").sub(/\s+$/, "").gsub(/\s+/, "-") +
            ".#{options[:extension]}"
          File.open("#{outdir}/#{fn}", "w:UTF-8") { |f| f.write bib.to_xml }
        end
      end

      desc "concatenate SOURCE-DIR COLLECTION-FILE", "Concatenate entries in DIRECTORY (containing Relaton-XML or YAML) into a Relaton Collection"

      option :title, :required => false, :desc => "Title of resulting Relaton collection", :aliases => :t
      option :organization, :required => false, :desc => "Organization owner of Relaton collection", :aliases => :g

      def concatenate(source_dir, outfile)

        Dir[ File.join(source_dir, '**', '*.yaml') ].reject { |p| File.directory? p }.each do |f|
          yaml2xml(f, nil, "rxl")
        end

        bibdatas = []
        Dir[ File.join(source_dir, '**', '*.{rxl}') ].reject { |p| File.directory? p }.each do |f|
          file = File.read(f, encoding: "utf-8")
          bibdata_doc = Nokogiri.XML(file)
          # Skip if this XML isn't a Relaton XML
          next unless bibdata_doc.root.name == "bibdata"
          # Force a namespace otherwise Nokogiri won't parse.
          # The reason is we use Bibcollection's from_xml, but that one has an xmlns.
          # We don't want to change the code for bibdata hence this hack
          #bibdata_doc.root['xmlns'] = "xmlns"
          bibdata_doc.remove_namespaces!
          bibdata_doc.root.add_namespace(nil, "xmlns")
          bibdata_doc = Nokogiri.XML(bibdata_doc.to_xml)

          bibdata = Relaton::Bibdata.from_xml(bibdata_doc.root)
          # XML relaton file must already exist
          bibdata.relaton = f
          xml = Pathname.new(f).sub_ext('.xml')
          bibdata.xml = xml if File.file?(xml) && f.match(/\.rxl$/)
          pdf = Pathname.new(f).sub_ext('.pdf')
          bibdata.pdf = pdf if File.file?(pdf)
          doc = Pathname.new(f).sub_ext('.doc')
          bibdata.doc = doc if File.file?(doc)
          html = Pathname.new(f).sub_ext('.html')
          bibdata.html = html if File.file?(html)
          bibdatas << bibdata
        end

        bibcollection = ::Relaton::Bibcollection.new(
          title: options[:title],
          # doctype: options[:doctype],
          author: options[:organization],
          items: bibdatas
        )
        File.open(outfile, "w:UTF-8") do |f|
          f.write bibcollection.to_xml
        end
      end

      desc "yaml2xml YAML", "Convert Relaton YAML into Relaton Collection XML or separate files"
      option :extension, aliases: :x, desc: "File extension of Relaton XML files, defaults to 'rxl'"
      option :prefix, aliases: :p, desc: "Filename prefix of individual Relaton XML files, defaults to empty"
      option :outdir, aliases: :o,  desc: "Output to the specified directory with individual Relaton Bibdata XML files"
      option :require, aliases: :r, type: :array, desc: "Require LIBRARY prior to execution"

      def yaml2xml(filename)
        Relaton::Cli::YAMLConvertor.to_xml(filename, options)
      end

      desc "xml2yaml XML", "Convert Relaton YAML into Relaton Bibcollection YAML (and separate files)"
      option :extension, aliases: :x, desc: "File extension of Relaton YAML files, defaults to 'yaml'"
      option :prefix, aliases: :p, desc: "Filename prefix of Relaton XML files, defaults to empty"
      option :outdir, aliases: :o, desc: "Output to the specified directory with individual Relaton Bibdata YAML files"
      option :require, aliases: :r, type: :array, desc: "Require LIBRARY prior to execution"

      def xml2yaml(filename)
        Relaton::Cli::XMLConvertor.to_yaml(filename, options)
      end

      desc "xml2html RELATON-INDEX-XML STYLESHEET LIQUID-TEMPLATE-DIR", "Convert Relaton Collection XML into HTML"

      def xml2html(filename, stylesheet, liquid_dir)
        file = File.read(filename, encoding: "utf-8")
        xml_to_html = Relaton::Cli::XmlToHtmlRenderer.new({
          stylesheet: stylesheet,
          liquid_dir: liquid_dir,
        })
        html_filename = Pathname.new(filename).sub_ext('.html')
        File.open(html_filename, "w:UTF-8") do |f|
          f.write(xml_to_html.render(file))
        end
      end

      desc "yaml2html YAML STYLESHEET LIQUID-TEMPLATE-DIR", "Concatenate Relaton YAML into HTML"

      def yaml2html(filename, stylesheet, liquid_dir)
        yaml2xml(filename, nil, "xml")
        outfilename = Pathname.new(filename).sub_ext('.xml')
        xml2html(outfilename, stylesheet, liquid_dir)
      end

      private

      def fetch_document(code, options)
        if registered_types.include?(options[:type])
          doc = Cli.relaton.fetch_std(code, options[:year], options[:type])
          doc ? doc.to_xml : "No matching bibliographic entry found"
        end
      end

      def supported_type_message
        ["Recognised types:", registered_types.sort.join(", ")].join(" ")
      end

      def registered_types
        @registered_types ||=
          Relaton::Registry.instance.processors.each.map { |_n, pr| pr.prefix }
      end
    end
  end
end
