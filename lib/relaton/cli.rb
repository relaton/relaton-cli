require "fileutils"
require "thor"
require "thor/hollaback"
require_relative "cli/version"
require_relative "cli/util"
require_relative "cli/command"

module Relaton
  def self.db(dir = nil)
    Cli.relaton dir
  end

  module Cli
    class RelatonDb
      include Singleton

      DBCONF = "#{Dir.home}/.relaton/dbpath".freeze

      # @param dir [String, nil]
      # @return [Relaton::Db]
      def db(dir)
        if dir
          FileUtils.mkdir_p File.dirname(DBCONF)
          File.write DBCONF, dir, encoding: "UTF-8"
          @db = Relaton::Db.new dir, nil
        else
          @db ||= Relaton::Db.new dbpath, nil
        end
      end

      private

      # @return [String] path to DB
      def dbpath
        if File.exist?(DBCONF)
          File.read(DBCONF, encoding: "UTF-8")
        else "#{Dir.home}/.relaton/cache"
        end
      end
    end

    class << self
      # The processor registry moved in relaton v3: the top-level
      # Relaton::Registry became Relaton::Db::Registry. The v2 line keeps
      # the old constant, so resolve whichever is present.
      def registry
        Relaton::Db::Registry.instance
      rescue NameError
        Relaton::Registry.instance
      end

      def version
        require "relaton/bib"
        registry = registry()
        puts "CLI => #{Relaton::Cli::VERSION}"
        puts "relaton => #{Gem.loaded_specs['relaton'].version}"
        registry.processors.each_key do |k|
          name = k.to_s.sub("_", "-")
          spec = Gem.loaded_specs[name]
          puts "#{name} => #{spec.version}" if spec
        end
      end

      def start(arguments)
        Relaton::Cli::Command.start(arguments)
      end

      # Relaton
      #
      # Based on current setup, we need to initiate a Db instance to
      # register all of it's supported processor backends. To make it
      # easier we have added it as a class method so we can use this
      # whenever necessary.
      #
      # @param dir [String, nil]
      # @return [Relaton::Db]
      def relaton(dir)
        RelatonDb.instance.db dir
      end

      # @param content [Nokogiri::XML::Document]
      # @return [RelatonBib::BibliographicItem,
      #   RelatonIsoBib::IsoBibliongraphicItem]
      def parse_xml(doc)
        doc.remove_namespaces! if doc.respond_to?(:remove_namespaces!)
        if (proc = Cli.processor(doc))
          proc.from_xml(doc.to_s)
        else
          Relaton::Bib::Item.from_xml(doc.to_s) rescue nil
        end
      end

      # @param doc [Nokogiri::XML::Element]
      # @return [RelatonIso::Processor, RelatonIec::Processor,
      #   RelatonNist::Processor, RelatonIetf::Processot,
      #   RelatonItu::Processor, RelatonGb::Processor,
      #   RelatonOgc::Processor, RelatonCalconnect::Processor]
      def processor(doc)
        docid = doc.at "docidentifier"
        proc = get_proc docid
        return proc if proc

        registry.by_type(docid&.text&.match(/^\w+/)&.to_s)
      end

      private

      # @param doc [Nokogiri::XML::Element]
      # @return [RelatonIso::Processor, RelatonIec::Processor,
      #   RelatonNist::Processor, RelatonIetf::Processot,
      #   RelatonItu::Processor, RelatonGb::Processor,
      #   RelatonOgc::Processor, RelatonCalconnect::Processor]
      def get_proc(docid)
        return unless docid && docid[:type]

        registry.by_type(docid[:type])
      end
    end
  end
end
