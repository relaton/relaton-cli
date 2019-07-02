require "fileutils"
require "relaton/bibdata"
require "relaton/bibcollection"
require "relaton/bibcollectionnew"
require "relaton/cli/xml_to_html_renderer"

module Relaton
  module Cli
    class BaseConvertor
      def initialize(file, options = {})
        @file = file
        @options = options
        @outdir = options.fetch(:outdir, nil)
        @writable = options.fetch(:write, true)
        @overwrite = options.fetch(:overwrite, true)

        install_dependencies(options[:require] || [])
      end

      def to_html
        content = convert_to_html
        write_to_a_file(content)
      end

      # Convert to HTML
      #
      # This interface expect us to provide Relaton collection XML
      # as XML/RXL, and necessary styels / templates then it will be
      # used convert that collection to HTML.
      #
      # @param file [String] Relaton collection file path
      # @param style [String] Stylesheet file path for styles
      # @param template [String] The liquid tempalte directory
      #
      def self.to_html(file, style = nil, template = nil)
        new(
          file,
          style: style || File.join(File.dirname(__FILE__), "../../../templates/index-style.css"),
          template: template || File.join(File.dirname(__FILE__), "../../../templates/"),
          extension: "html"
        ).to_html
      end

      private

      attr_reader :file, :outdir, :options, :writable, :overwrite

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
      
      def item_output(content, format)
        case format.to_sym
                        when :to_yaml then content.to_yaml
                        when :to_xml then content.to_xml(date_format: :full)
                        end
      end

      def convert_and_write(content, format)
        content = convert_content(content)
        write_to_a_file(item_output(content, format))
        write_to_file_collection(content, format.to_sym)
      end

      def write_to_a_file(content, outfile = nil)
        outfile ||= Pathname.new(file).sub_ext(extension).to_s

        if !File.exists?(outfile) || overwrite
          File.open(outfile, "w:utf-8") { |file| file.write(content) }
        end
      end

      def write_to_file_collection(content, format)
        if outdir && content.is_a?(Relaton::Bibcollection)
          FileUtils.mkdir_p(outdir)
          content.items_flattened.each do |item|
            collection = collection_filename(item.docidentifier_code)
            write_to_a_file(item_output(item, format), collection)
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
