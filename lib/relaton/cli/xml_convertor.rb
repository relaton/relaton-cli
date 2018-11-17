require "nokogiri"
require "relaton/cli/base_convertor"

module Relaton
  module Cli
    class XMLConvertor < Relaton::Cli::BaseConvertor
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

      def convert_content(content)
        Relaton::Bibcollection.from_xml(content)
      end

      def file_content
        Nokogiri::XML(File.read(file, encoding: "utf-8"))
      end
    end
  end
end
