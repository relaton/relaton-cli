require "yaml"
require "relaton/cli/base_convertor"
require "relaton_bib"

module Relaton
  module Cli
    class YAMLConvertorNew < Relaton::Cli::BaseConvertor
      def to_xml
        if writable
          convert_and_write(file_content, :to_xml)
        else
          convert_content(file_content).to_xml(nil, date_format: :full, bibdata: true)
        end
      end

      # Convert to XML
      #
      # This interface allow us to convert any YAML file to XML.
      # It only require us to provide a valid YAML file and it can
      # do converstion using default attributes, but it also allow
      # us to provide custom options to customize this converstion
      # process.
      #
      # @param file [File] The complete path to a YAML file
      # @param options [Hash] Options as hash key, value pairs.
      #
      def self.to_xml(file, options = {})
        new(file, options).to_xml
      end

      private

      def default_ext
        "rxl"
      end

      def file_content
        date_to_string(YAML.load_file(file))
      end

      def date_to_string(obj)
        obj.is_a? Hash and
          return obj.inject({}){|memo,(k,v)| memo[k] = date_to_string(v); memo}
        obj.is_a? Array and
          return obj.inject([]){|memo,v    | memo      << date_to_string(v); memo}
        return obj.is_a?(Date) ? obj.to_s : obj
      end

      def convert_single_file(content)
        docid = content["docid"].is_a?(Array) ? content["docid"][0] : content["docid"]
        if (processor = Relaton::Registry.instance.by_type(docid["type"]))
          processor.hash_to_bib content
        else
          RelatonBib::BibliographicItem.new(RelatonBib::HashConverter::hash_to_bib(content))
        end
      end

      def convert_collection(content)
        if content.has_key?("root")
          content["root"]["items"] = content["root"]["items"].map do |i|
            # RelatonBib::HashConverter::hash_to_bib(i)
            convert_single_file(i)
          end
          Relaton::BibcollectionNew.new(content["root"])
        end
      end

      def xml_content(_raw_file)
        convert_content(file_content).to_xml(date_format: :full, bibdata: true)
      end

      def convert_content(content)
        convert_collection(content) || convert_single_file(content)
      end
    end
  end
end
