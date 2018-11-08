module Relaton
  module Cli
    class BaseConvertor
      def initialize(file, options = {})
        @file = file
        @options = options
        @outdir = options.fetch(:outdir, nil)
        @writable = options.fetch(:write, true)

        install_dependencies(options[:require] || [])
      end

      def to_html
        content = convert_to_html
        write_to_a_file(content)
      end

      def self.to_html(file, style, template)
        new(file, style: style, template: template, extension: "html").to_html
      end

      private

      attr_reader :file, :outdir, :options, :writable

      def default_ext
        raise "Override this method"
      end

      def convert_to_html
        Relaton::Cli::XmlToHtmlRenderer.render(
          xml_content(file),
          stylesheet: options[:style],
          liquid_dir: options[:template],
        )
      end

      def xml_content(file)
        File.read(file, encoding: "utf-8")
      end

      def install_dependencies(dependencies)
        dependencies.each { |dependency| require(dependency) }
      end

      def convert_and_write(content, format)
        content = convert_content(content)
        write_to_a_file(content.send(format.to_sym))
        write_to_file_collection(content, format.to_sym)
      end

      def write_to_a_file(content, outfile = nil)
        outfile ||= Pathname.new(file).sub_ext(extension).to_s
        File.open(outfile, "w:utf-8") { |file| file.write(content) }
      end

      def write_to_file_collection(content, format)
        if outdir && content.is_a?(Relaton::Bibcollection)
          FileUtils.mkdir_p(outdir)

          content.items_flattened.each do |item|
            collection = collection_filename(item.docidentifier_code)
            write_to_a_file(item.send(format.to_sym), collection)
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
