require "nokogiri"
require "relaton/cli/base_convertor"

module Relaton
  module Cli
    class XMLConvertor < Relaton::Cli::BaseConvertor
      def to_yaml
        convert_and_write(file_content, :to_yaml)
      end

      def self.to_yaml(file, options = {})
        new(file, options).to_yaml
      end

      private

      def default_ext
        "yaml"
      end

      def convert_content(content)
        Relaton::Bibcollection.from_xml(content)
      end

      def file_content
        Nokogiri::XML(File.read(file, encoding: "utf-8"))
      end
    end
  end
end
