require "relaton/cli/relaton_file"
require "relaton/cli/xml_convertor"
require "relaton/cli/yaml_convertor"
require "fcntl"

module Relaton
  module Cli
    class Command < Thor
      desc "fetch CODE", "Fetch Relaton XML for Standard identifier CODE"
      option :type, aliases: :t, required: true, desc: "Type of standard to get bibliographic entry for"
      option :year, aliases: :y, type: :numeric, desc: "Year the standard was published"

      def fetch(code)
        Relaton::Cli.relaton
        io = IO.new(STDOUT.fcntl(::Fcntl::F_DUPFD), mode: 'w:UTF-8')
        io.puts(fetch_document(code, options) || supported_type_message)
      end

      desc "extract Metanorma-XML-File / Directory Relaton-XML-Directory", "Extract Relaton XML from Metanorma XML file / directory"
      option :extension, aliases: :x, desc: "File extension of Relaton XML files, defaults to 'rxl'"

      def extract(source_dir, outdir)
        Relaton::Cli::RelatonFile.extract(source_dir, outdir, options)
      end

      desc "concatenate SOURCE-DIR COLLECTION-FILE", "Concatenate entries in DIRECTORY (containing Relaton-XML or YAML) into a Relaton Collection"
      option :title, aliases: :t,  desc: "Title of resulting Relaton collection"
      option :organization, aliases: :g, desc: "Organization owner of Relaton collection"

      def concatenate(source_dir, outfile)
        Relaton::Cli::RelatonFile.concatenate(source_dir, outfile, options)
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

      desc "xml2html RELATON-INDEX-XML", "Convert Relaton Collection XML into HTML"
      option :stylesheet, aliases: :s, desc: "Stylesheet file path for rendering HTML index"
      option :templatedir, aliases: :t, desc: "Liquid template directory for rendering Relaton items and collection"

      def xml2html(file, style = nil, template = nil)
        Relaton::Cli::XMLConvertor.to_html(file, style, template)
      end

      desc "yaml2html RELATON-INDEX-YAML", "Concatenate Relaton Collection YAML into HTML"
      option :stylesheet, aliases: :s, desc: "Stylesheet file path for rendering HTML index"
      option :templatedir, aliases: :t, desc: "Liquid template directory for rendering Relaton items and collection"

      def yaml2html(file, style = nil, template = nil)
        Relaton::Cli::YAMLConvertor.to_html(file, style, template)
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
