module Relaton
  module Cli
    class YAMLConvertor
      def initialize(file, extension: :rxl, **options)
        @file = file
        @options = options
        @outdir = options.fetch(:outdir, nil)
        @extension = [".", extension.to_s].join("")

        require_dependencies(options[:require])
      end

      def to_xml
        content = convert_content(load_yaml_content)
        write_to_single_file(content.to_xml)
        write_to_collection_if_applicable(content)
      end

      def self.to_xml(file, options = {})
        new(file, options).to_xml
      end

      private

      attr_reader :file, :outdir, :extension

      def load_yaml_content
        require "yaml"
        YAML.load_file(file)
      end

      def collection?
        content.has_key?("root")
      end

      def require_dependencies(dependencies)
        unless dependencies.nil?
          dependencies.each do |dependency|
            require(dependency)
          end
        end
      end

      def write_to_single_file(content, outfile = nil)
        outfile ||= Pathname.new(file).sub_ext(extension).to_s
        File.open(outfile, "w:utf-8") { |file| file.write(content) }
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

      def write_to_collection_if_applicable(content)
        if outdir && content.is_a?(Relaton::Bibcollection)
          FileUtils.mkdir_p(outdir)

          content.items_flattened.each do |item|
            collection = build_collection_file(item.docidentifier_code)
            write_to_single_file(item.to_xml, collection)
          end
        end
      end

      def build_collection_file(identifier)
        File.join(
          outdir, [@options[:prefix], identifier, extension].compact.join("")
        )
      end
    end
  end
end
