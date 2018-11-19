require "yaml"
require "relaton/cli/base_convertor"

module Relaton
  module Cli
    class YAMLConvertor < Relaton::Cli::BaseConvertor
      def to_xml
        if writable
          convert_and_write(file_content, :to_xml)
        else
          convert_content(file_content).to_xml
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
        YAML.load_file(file)
      end

      def convert_single_file(content)
        Relaton::Bibdata.new(content)
      end

      def convert_collection(content)
        if content.has_key?("root")
          Relaton::Bibcollection.new(content["root"])
        end
      end

      def xml_content(_raw_file)
        convert_content(file_content).to_xml
      end

      def convert_content(content)
        convert_collection(content) || convert_single_file(content)
      end
    end
  end
end
