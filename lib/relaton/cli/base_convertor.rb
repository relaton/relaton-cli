module Relaton
  module Cli
    class BaseConvertor
      def initialize(file, options = {})
        @file = file
        @options = options
        @outdir = options.fetch(:outdir, nil)

        install_dependencies(options[:require] || [])
      end

      private

      attr_reader :file, :outdir, :options

      def default_ext
        raise "Override this method"
      end

      def convert_and_write(content, format)
        content = convert_content(content)
        write_to_a_file(content, format.to_sym)
        write_to_file_collection(content, format.to_sym)
      end

      def install_dependencies(dependencies)
        dependencies.each { |dependency| require(dependency) }
      end

      def write_to_a_file(content, format, outfile = nil)
        outfile ||= Pathname.new(file).sub_ext(extension).to_s

        File.open(outfile, "w:utf-8") do |file|
          file.write(content.send(format.to_sym))
        end
      end

      def write_to_file_collection(content, format)
        if outdir && content.is_a?(Relaton::Bibcollection)
          FileUtils.mkdir_p(outdir)

          content.items_flattened.each do |item|
            collection = collection_filename(item.docidentifier_code)
            write_to_a_file(item, format, collection)
          end
        end
      end

      def extension
        @extension ||= [".", options.fetch(:extension, default_ext)].join
      end

      def collection_filename(identifier)
        File.join(
          outdir, [@options[:prefix], identifier, extension].compact.join("")
        )
      end
    end
  end
end
