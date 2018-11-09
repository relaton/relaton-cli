require "yaml"
require "relaton/cli/base_convertor"

module Relaton
  module Cli
    class YAMLConvertor < Relaton::Cli::BaseConvertor
      def to_xml
        convert_and_write(file_content, :to_xml)
      end

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

      def convert_content(content)
        convert_collection(content) || convert_single_file(content)
      end
    end
  end
end
