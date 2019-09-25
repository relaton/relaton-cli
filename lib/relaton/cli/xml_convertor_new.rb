require "nokogiri"
require "relaton/cli/base_convertor"

module Relaton
  module Cli
    class XMLConvertorNew < Relaton::Cli::BaseConvertor
      def to_yaml
        convert_and_write(file_content, :to_yaml)
      end

      # Convert to YAML
      #
      # This interface allow us to convert any XML file to YAML.
      # It only require us to provide a valid XML file and it can
      # do converstion using default attributes, but it also allow
      # us to provide custom options to customize this converstion
      # process.
      #
      # @param file [File] The complete path to a XML file
      # @param options [Hash] Options as hash key, value pairs.
      #
      def self.to_yaml(file, options = {})
        new(file, options).to_yaml
      end

      private

      def default_ext
        "yaml"
      end

      # @param content [Nokogiri::XML::Document]
      # @return [Hash]
      def convert_content(content)
        if content.root.name == "bibdata"
          # Bibdata.from_xml(content.to_s)
          convert_bibdata content
        else
          # Bibcollection.from_xml(content)
          title = content.at("relaton-collection/title").text
          author = content.at("relaton-collection/contributor/organization/name").text
          collection = { "root" => { "title" => title, "author" => author } }

          collection["root"]["items"] = content.xpath("//bibdata").map do |bib|
            convert_bibdata bib
          end

          collection
        end
      end

      # @param content [Nokogiri::XML::Document]
      # @return [Hash]
      def convert_bibdata(doc)
        if (processor = Relaton::Registry.instance.by_type(doctype(doc)))
          processor.from_xml(doc.to_s).to_hash
        else
          RelatonBib::XMLParser.from_xml(doc.to_s).to_hash
        end
      end

      # @param content [Nokogiri::XML::Document]
      # @return [String]
      def doctype(doc)
        docid = doc.at "//docidentifier"
        return docid[:type] if docid && docid[:type]

        docid.text.match(/^\w+/).to_s
      end

      def file_content
        Nokogiri::XML(File.read(file, encoding: "utf-8")).remove_namespaces!
      end
    end
  end
end
