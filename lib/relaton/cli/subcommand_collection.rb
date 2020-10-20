require "relaton/cli/full_text_search"

module Relaton
  module Cli
    class SubcommandCollection < Thor
      desc "create", "Create collection"
      option :dir, desc: "Directory to store collection. Default is "\
        "$HOME/.relaton/collections."
      option :author, desc: "Author"
      option :title, desc: "Title"
      option :doctype, desc: "Documents type"
      def create(file)
        dir = directory
        col = Relaton::Bibcollection.new options
        Dir.mkdir dir unless Dir.exist? dir
        File.write File.join(dir, file), col.to_yaml, encoding: "UTF-8"
      end

      desc "info", "View collection information"
      def info(file) # rubocop:disable Metrics/AbcSize
        puts "Collection: #{File.basename file}"
        puts "Last updated: #{File.mtime file}"
        puts "File size: #{File.size file}"
        col = Relaton::Bibcollection.new YAML.load_file(file)["root"]
        puts "Number of items: #{col.items.size}"
        puts "Author: #{col.author}"
        puts "Title: #{col.title}"
      end

      desc "list", "List collections"
      option :dir, desc: "Directory with collections. Default is "\
        "$HOME/.relaton/collections."
      def list
        Dir[File.join(directory, "*")].each do |f|
          yml = read_yaml f
          puts File.basename f if yml && yml["root"]
        end
      end

      map ls: :list

      desc "get", "Fetch document from collection"
      option :collection, desc: "Collection to fetch document. By default "\
        "fetch the first match across all collections."
      option :dir, desc: "Directory with collections. Default is "\
        "$HOME/.relaton/collections."
      def get(docid)
        collections.each do |col|
          col[:collection].items.each do |item|
            if item.docidentifier.detect { |di| di.id == docid }
              puts item.to_xml bibdata: true
              return
            end
          end
        end
      end

      desc "find", "Full-text search"
      option :collection, desc: "Collection to search text. By default "\
        "search across all collections."
      option :dir, desc: "Directory with collections. Default is "\
        "$HOME/.relaton/collections."
      def find(text)
        collections.each do |col|
          searcher = Relaton::FullTextSeatch.new(col[:collection])
          searcher.search text
          if searcher.any?
            puts "Collection: #{File.basename(col[:file])}"
            searcher.print_results
          end
        end
      end

      map search: :find

      private

      # @return [String]
      def directory
        options.fetch :dir, File.join(Dir.home, ".relaton/collections")
      end

      # @param file [String]
      # @return [Hash]
      def read_yaml(file)
        YAML.load_file file if File.file? file
      rescue Psych::SyntaxError
      end

      # @return [Array<Hash>]
      def collections
        file = options.fetch :collection, "*"
        Dir[File.join directory, file].reduce([]) do |m, f|
          yml = read_yaml f
          if yml && yml["root"]
            m << { collection: Relaton::Bibcollection.new(yml["root"]), file: f }
          end
          m
        end
      end
    end
  end
end
