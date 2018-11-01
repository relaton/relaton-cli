require "relaton"
require "nokogiri"
require "yaml"
require "thor"
require "fileutils"
require "pathname"

module Relaton
  module Cli
    class Command < Thor
      desc "fetch CODE", "Fetch Relaton XML for Standard identifier CODE"

      option :type, :required => true, :desc => "Type of standard to get bibliographic entry for", :aliases => :t
      option :year, :desc => "Year the standard was published", :aliases => :y, :type => :numeric

      def fetch(code)
        relaton = Relaton::Db.new("#{Dir.home}/.relaton-bib.pstore", nil)
        registry = Relaton::Registry.instance
        types = []
        registry.processors.each { |_n, pr| types << pr.prefix }
        if types.include?(options[:type])
          ret = relaton.fetch_std(code, options[:year], options[:type], {})
          say(ret.nil? ? "No matching bibliographic entry found" : ret.to_xml)
        else
          say "Recognised types: #{types.sort.join(', ')}"
        end
      end

      desc "extract Metanorma-XML-Directory Relaton-XML-File", "Extract Relaton XML from folder of Metanorma XML"

      option :extension, :required => false, :desc => "File extension of Relaton XML files, defaults to '.rxl'", :aliases => :x, :default => ".rxl"

      def extract(source_dir, outfile)
        Dir.foreach indir do |f|
          next unless /\.xml\Z/.match f

          xml = Nokogiri::XML(File.read("#{indir}/#{f}", encoding: "utf-8"))
          bib = xml.at("//xmlns:bibdata") || next

          docidentifier = bib&.at("./xmlns:docidentifier")&.text ||
            Pathname.new(f).sub_ext('.xml').to_s

          fn = docidentifier.sub(/^\s+/, "").sub(/\s+$/, "").gsub(/\s+/, "-") +
            ".#{options[:extension]}"

          File.open("#{outdir}/#{fn}", "w:UTF-8") { |f| f.write bib.to_xml }
        end
      end

      desc "concatenate SOURCE-DIR COLLECTION-FILE", "Concatenate entries in DIRECTORY (containing Relaton-XML or YAML) into a Relaton Collection"

      option :title, :required => false, :desc => "Title of resulting Relaton collection", :aliases => :t
      option :organization, :required => false, :desc => "Organization owner of Relaton collection", :aliases => :g

      def concatenate(source_dir, outfile)
        Dir.foreach source_dir do |f|
          /\.yaml$/.match(f) and yaml2xml("#{dir}/#{f}", dir)
        end

        bibdatas = []
        Dir[ File.join(source_dir, '**', '*.{xml,rxl}') ].reject { |p| File.directory? p }.each do |f|
          file = File.read(f, encoding: "utf-8")
          bibdata_doc = Nokogiri.XML(file)
          # Skip if this XML isn't a Relaton XML
          next unless bibdata_doc.root.name == "bibdata"

          # Force a namespace otherwise Nokogiri won't parse.
          # The reason is we use Bibcollection's from_xml, but that one has an xmlns.
          # We don't want to change the code for bibdata hence this hack
          bibdata_doc.root['xmlns'] = "xmlns"
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

        doc_number_regex = /([\w\/]+)\s+(\d+):?(\d*)/
        bibdatas.sort_by! do |b|
          b.docidentifier.match(doc_number_regex) ? $2 : 999999
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

      desc "yaml2xml YAML OUTPUT-DIRECTORY", "Convert Relaton YAML into Relaton Collection XML"

      option :extension, :required => false, :desc => "File extension of Relaton XML files, defaults to '.rxl'", :aliases => :x, :default => ".rxl"
      option :prefix, :required => false, :desc => "Filename prefix of Relaton XML files, defaults to empty", :aliases => :p
      option :require, :required => false, :desc => "Require LIBRARY prior to execution", :aliases => :r, :type => :array

      def yaml2xml(filename, outdir)
        if options[:require]
          options[:require].each do |r|
            require r
          end
        end
        index_input = YAML.load_file(filename)
        index_collection = ::Relaton::Bibcollection.new(index_input["root"])
        # TODO real lookup of namespaces and root elements
        outfilename = Pathname.new(filename).sub_ext('.xml')
        File.open(outfilename, "w:utf-8") { |f| f.write index_collection.to_xml }
        return unless outdir
        FileUtils.mkdir_p(outdir)
        index_collection.items_flattened.each do |item|
          filename = File.join(outdir, "#{options[:prefix]}#{item.docidentifier_code}.#{options[:extension]}")
          File.open(filename, "w:UTF-8") { |f| f.write(item.to_xml) }
        end
      end

      desc "xml2html <relaton-index-xml> <stylesheet> <liquid-template-dir>", "Convert Relaton Collection XML into HTML"

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

      desc "yaml2html YAML <stylesheet> <liquid-template-dir>", "Concatenate Relaton YAML into HTML"

      def yaml2html(filename, stylesheet, liquid_dir)
        yaml2xml(filename, nil)
        outfilename = Pathname.new(filename).sub_ext('.xml')
        xml2html(outfilename, stylesheet, liquid_dir)
      end
    end
  end
end


