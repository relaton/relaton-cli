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

      def self.extract(source, outdir, options = {})
        new(source, options.merge(outdir: outdir)).extract
      end

      def self.concatenate(source, outfile, options = {})
        new(source, options.merge(outfile: outfile)).concatenate
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

      def extract_and_write_to_files
        select_files_with("xml").each do |file|
          xml = nokogiri_document(nil, file).remove_namespaces!

          bib = xml.at("//bibdata") || next
          bib.add_namespace(nil, "")

          outfile = [outdir, build_filename(file, bib)].join("/")
          write_to_file(bib.to_xml, outfile)
        end
      end

      def concatenate_files
        [convert_rxl_to_xml, convert_yamls_to_xml].flatten.map do |xml|
          doc = nokogiri_document(xml[:content])
          bibdata_instance(doc, xml[:file]) if doc.root.name == "bibdata"
        end.compact
      end

      def bibdata_instance(document, file)
        document = clean_nokogiri_document(document)
        bibdata = Relaton::Bibdata.from_xml(document.root)
        build_bibdata_relaton(bibdata, file)

        bibdata
      end

      def build_bibdata_relaton(bibdata, file)
        ["xml", "pdf", "doc", "html"].each do |type|
          file = Pathname.new(file).sub_ext(".#{type}")
          bibdata.send("#{type}=", file) if File.file?(file)
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
        select_files_with("yaml").map do |file|
          { file: file, content: YAMLConvertor.to_xml(file, write: false) }
        end
      end

      def select_files_with(extension)
        files = File.join(source, "**", "*.#{extension}")
        Dir[files].reject { |file| File.directory?(file) }
      end

      def write_to_file(content, output_file = nil)
        output_file ||= outfile
        File.open(output_file, "w:utf-8") { |file| file.write(content) }
      end

      def build_filename(file, document)
        identifier = document&.at("./docidentifier")&.text ||
          Pathname.new(File.basename(file, ".xml")).to_s

        filename = identifier.sub(/^\s+/, "").sub(/\s+$/, "").gsub(/\s+/, "-")
        [filename, options[:extension] || "rxl"].join(".")
      end
    end
  end
end
