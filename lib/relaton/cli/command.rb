require "relaton"
require "nokogiri"
require "yaml"
require "thor"
require "fileutils"

module Relaton
  module Cli
    class Command < Thor
      desc "concatenate DIRECTORY", "Concatenate entries in DIRECTORY (containing Relaton-XML or YAML) into a Relaton Collection"

      def concatenate(dir)
        ret = ""
        Dir.foreach dir do |f|
          /\.yaml$/.match(f) and
            #TODO come back to this
            system "#{__dir__}/relaton-yaml-xml -R #{dir} #{dir}/#{f}"
        end
        Dir.foreach dir do |f|
          /\.xml$/.match(f) and
            ret += File.read("#{dir}/#{f}", encoding: "utf-8")
        end
        say "<relaton-collection>\n#{ret}\n</relaton-collection>"
      end

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

      desc "extract Metanorma-XML-Directory Relaton-XML-Directory", "Extract Relaton XML from folder of Metanorma XML"

      def extract(indir, outdir)
        Dir.foreach indir do |f|
          if /\.xml$/.match f
            xml = Nokogiri::XML(File.read("#{indir}/#{f}", encoding: "utf-8"))
            bib = xml.at("//xmlns:bibdata") || next
            docid = bib&.at("./xmlns:docidentifier")&.text || f.sub(/\.xml$/, "")
            fn = docid.sub(/^\s+/, "").sub(/\s+$/, "").gsub(/\s+/, "-") + ".xml"
            File.open("#{outdir}/#{fn}", "w:UTF-8") { |f| f.write bib.to_xml }
          end
        end
      end

      desc "yaml2xml YAML OUTPUT-DIRECTORY", "Convert Relaton YAML into Relaton Collection XML"

      def yaml2xml(filename, outdir)
        index_input = YAML.load_file(filename)
        coll = ::Relaton::Bibcollection.new(index_input["root"])
        outfilename = filename.sub(/\.[^.]+$/, ".xml")
        File.open(outfilename, "w:utf-8") { |f| f.write coll.to_xml }
        return unless outdir
        FileUtils.mkdir_p(outdir)
        coll.items_flattened.each do |item|
          itemname = File.join(outdir, "#{item.docid_code}.xml")
          File.open(itemname, "w:UTF-8") { |f| f.write(item.to_xml) }
        end
      end

      desc "xml2html <relaton-index-xml> <stylesheet> <liquid-template-dir>", "Convert Relaton Collection XML into HTML"

      def xml2html(filename, stylesheet, liquid_dir)
        file = File.read(filename, encoding: "utf-8")
        xml_to_html = Relaton::Cli::XmlToHtmlRenderer.new({
          stylesheet: stylesheet,
          liquid_dir: liquid_dir,
        })
        File.open(filename.sub(/\.xml$/, ".html"), "w:UTF-8") do |f|
          f.write(xml_to_html.render(file))
        end
      end

      desc "yaml2html YAML <stylesheet> <liquid-template-dir>", "Concatenate Relaton YAML into HTML"

      def yaml2html(filename, stylesheet, liquid_dir)
        yaml2xml(filename, nil)
        outfilename = filename.sub(/\.[^.]+$/, ".xml")
        xml2html(outfilename, stylesheet, liquid_dir)
      end
    end
  end
end


