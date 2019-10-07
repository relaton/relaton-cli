require "nokogiri"
require "pathname"

module Relaton
  module Cli
    class RelatonFile
      def initialize(source, options = {})
        @source = source
        @options = options
        @outdir = options.fetch(:outdir, nil)
        @outfile = options.fetch(:outfile, nil)
      end

      def extract
        extract_and_write_to_files
      end

      def concatenate
        write_to_file(bibcollection.to_xml)
      end

      def split
        split_and_write_to_files
      end

      # Extract files
      #
      # This interface expect us to provide a source file / directory,
      # output directory and custom configuration options. Then it wll
      # extract Relaton XML file / files to output directory from the
      # source file / directory. During this process it will use custom
      # options when available.
      #
      # @param source [Dir] The source directory for files
      # @param outdir [Dir] The output directory for files
      # @param options [Hash] Options as hash key value pair
      #
      def self.extract(source, outdir, options = {})
        new(source, options.merge(outdir: outdir)).extract
      end

      # Concatenate files
      #
      # This interface expect us to provide a source directory, output
      # file and custom configuration options. Normally, this expect the
      # source directory to contain RXL fles, but it also converts any
      # YAML files to RXL and then finally combines those together.
      #
      # This interface also allow us to provdie options like title and
      # organization and then it usage those details to generate the
      # collection file.
      #
      # @param source [Dir] The source directory for files
      # @param output [String] The collection output file
      # @param options [Hash] Options as hash key value pair
      #
      def self.concatenate(source, outfile, options = {})
        new(source, options.merge(outfile: outfile)).concatenate
      end

      # Split collection
      #
      # This interface expects us to provide a Relaton Collection
      # file and also an output directory, then it will split that
      # collection into multiple files.
      #
      # By default it usages `rxl` extension for these new files,
      # but we can also customize that by providing the correct
      # one as `extension` option parameter.
      #
      # @param source [File] The source collection file
      # @param output [Dir] The output directory for files
      # @param options [Hash] Options as hash key value pair
      #
      def self.split(source, outdir = nil, options = {})
        new(source, options.merge(outdir: outdir)).split
      end

      private

      attr_reader :source, :options, :outdir, :outfile

      def bibcollection
        ::Relaton::Bibcollection.new(
          title: options[:title],
          items: concatenate_files,
          doctype: options[:doctype],
          author: options[:organization],
        )
      end

      def nokogiri_document(document, file = nil)
        document ||= File.read(file, encoding: "utf-8")
        Nokogiri.XML(document)
      end

      def select_source_files
        if File.file?(source)
          [source]
        else
          select_files_with("xml")
        end
      end

      def relaton_collection
        @relaton_collection ||=
          Relaton::Bibcollection.from_xml(nokogiri_document(nil, source))
      end

      def extract_and_write_to_files
        select_source_files.each do |file|
          xml = nokogiri_document(nil, file)
          xml.remove_namespaces!

          if (bib = xml.at("//bibdata"))
            bib = nokogiri_document(bib.to_xml)
          elsif (rfc = xml.at("//rfc"))
            require "relaton_ietf/scrapper"
            #ietf = RelatonIetf::Scrapper.bib_item rfc, "rfc"
            ietf = RelatonIetf::Scrapper.fetch_rfc rfc
            bib = nokogiri_document ietf.to_xml(bibdata: true)
          else
            next
          end

          bib.remove_namespaces!
          bib.root.add_namespace(nil, "xmlns")

          bibdata = Relaton::Bibdata.from_xml(bib.root)
          build_bibdata_relaton(bibdata, file)

          write_to_file(bibdata.to_xml, outdir, build_filename(file))
        end
      end

      def concatenate_files
        xml_files = [convert_rxl_to_xml, convert_yamls_to_xml, convert_xml_to_xml]

        xml_files.flatten.map do |xml|
          doc = nokogiri_document(xml[:content])
          if (rfc = doc.at("//rfc"))
            require "relaton_ietf/scrapper"
            #ietf = RelatonIetf::Scrapper.bib_item rfc, "rfc"
            ietf = RelatonIetf::Scrapper.fetch_rfc rfc
            doc = nokogiri_document ietf.to_xml(bibdata: true)
          end
          bibdata_instance(doc, xml[:file]) if doc.root.name == "bibdata"
        end.compact
      end

      def split_and_write_to_files
        output_dir = outdir || build_dirname(source)

        relaton_collection.items.each do |content|
          name = build_filename(nil, content.docidentifier)
          find_available_bibrxl_file(name, output_dir, content)
          write_to_file(content.send(output_type), output_dir, name)
        end
      end

      def find_available_bibrxl_file(name, ouputdir, content)
        if options[:extension] == "yaml" || options[:extension] == "yml"
          bib_rxl = Pathname.new([outdir, name].join("/")).sub_ext(".rxl")
          content.bib_rxl = bib_rxl.to_s if File.file?(bib_rxl)
        end
      end

      def output_type
        output_format = options[:extension] || "rxl"
        (output_format == "rxl" ? "to_xml" : "to_#{output_format}").to_sym
      end

      def bibdata_instance(document, file)
        document = clean_nokogiri_document(document)
        bibdata = if options[:new]
                    Relaton::BibdataNew.from_xml document.root
                  else
                    Relaton::Bibdata.from_xml(document.root)
                  end
        build_bibdata_relaton(bibdata, file)

        bibdata
      end

      # @param content [Nokogiri::XML::Document]
      # @return [Hash]
      def parse_doc(doc)
        if (processor = Relaton::Registry.instance.by_type(doctype(doc)))
          processor.from_xml(doc.to_s).to_hash
        else
          RelatonBib::XMLParser.from_xml(doc.to_s).to_hash
        end
      end

      def build_bibdata_relaton(bibdata, file)
        ["xml", "pdf", "doc", "html", "rxl", "txt"].each do |type|
          file = Pathname.new(file).sub_ext(".#{type}")
          bibdata.send("#{type}=", file.to_s) if File.file?(file)
        end
      end

      # Force a namespace otherwise Nokogiri won't parse.
      # The reason is we use Bibcollection's from_xml, but that one
      # has an xmlns. We don't want to change the code for bibdata
      # hence this hack #bibdata_doc.root['xmlns'] = "xmlns"
      #
      def clean_nokogiri_document(document)
        document.remove_namespaces!
        document.root.add_namespace(nil, "xmlns")
        nokogiri_document(document.to_xml)
      end

      def convert_rxl_to_xml
        select_files_with("{rxl}").map do |file|
          { file: file, content: File.read(file, encoding: "utf-8") }
        end
      end

      def convert_yamls_to_xml
        klass = options[:new] ? YAMLConvertorNew : YAMLConvertor
        select_files_with("yaml").map do |file|
          { file: file, content: klass.to_xml(file, write: false) }
        end
      end

      def convert_xml_to_xml
        select_files_with("{xml}").map do |file|
          { file: file, content: File.read(file, encoding: "utf-8") }
        end
      end

      def select_files_with(extension)
        files = File.join(source, "**", "*.#{extension}")
        Dir[files].reject { |file| File.directory?(file) }
      end

      def write_to_file(content, directory = nil, output_file = nil)
        file_with_dir = [directory, output_file || outfile].compact.join("/")
        File.open(file_with_dir, "w:utf-8") { |file| file.write(content) }
      end

      def build_dirname(filename)
        basename = File.basename(filename)&.gsub(/.(xml|rxl)/, "")
        directory_name = sanitize_string(basename)
        Dir.mkdir(directory_name) unless File.exists?(directory_name)

        directory_name
      end

      def build_filename(file, identifier = nil, ext = "rxl")
        identifier ||= Pathname.new(File.basename(file, ".xml")).to_s
        [sanitize_string(identifier), options[:extension] || ext].join(".")
      end

      def sanitize_string(string)
        clean_string = replace_bad_characters(string.downcase)
        clean_string.gsub(/^\s+/, "").gsub(/\s+$/, "").gsub(/\s+/, "-")
      end

      def replace_bad_characters(string)
        bad_chars = ["/", "\\", "?", "%", "*", ":", "|", '"', "<", ">", ".", " "]
        bad_chars.inject(string.downcase) { |res, char| res.gsub(char, "-") }
      end
    end
  end
end
