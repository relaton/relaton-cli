module Relaton
  module Cli
    class Concatenator
      def initialize(source, outfile, options = {})
        @source = source
        @outfile = outfile
        @options = options
      end

      def concatenate
        write_to_file(bibcollection.to_xml)
      end

      def self.concatenate(source, outfile, options = {})
        new(source, outfile, options).concatenate
      end

      private

      attr_reader :source, :options, :outfile

      def bibcollection
        ::Relaton::Bibcollection.new(
          title: options[:title],
          items: concatenate_files,
          doctype: options[:doctype],
          author: options[:organization],
        )
      end

      def concatenate_files
        [convert_rxl_to_xml, convert_yamls_to_xml].flatten.map do |xml|
          doc = Nokogiri.XML(xml[:content])
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
        Nokogiri.XML(document.to_xml)
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

      def write_to_file(content)
        File.open(outfile, "w:utf-8") { |file| file.write(content) }
      end
    end
  end
end
