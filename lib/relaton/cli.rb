require "thor"
require "relaton"
require_relative "cli/command"

module Relaton
  def self.db
    Cli.relaton
  end

  module Cli
    class RelatonDb
      include Singleton

      def db
        @db ||= Relaton::Db.new("#{Dir.home}/.relaton/cache", nil)
      end
    end

    class << self
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
      def relaton
        RelatonDb.instance.db
      end

      # @param content [Nokogiri::XML::Document]
      # @return [RelatonBib::BibliographicItem,
      #   RelatonIsoBib::IsoBibliongraphicItem]
      def parse_xml(doc)
        if (proc = Cli.processor(doc))
          proc.from_xml(doc.to_s)
        else
          RelatonBib::XMLParser.from_xml(doc.to_s)
        end
      end

      # @param doc [Nokogiri::XML::Element]
      # @return [String] Type prefix
      def processor(doc) # rubocop:disable Metrics/CyclomaticComplexity
        docid = doc.at "docidentifier"
        if docid && docid[:type]
          proc = Relaton::Registry.instance.by_type(docid[:type])
          return proc if proc
        end
        Relaton::Registry.instance.by_type(docid&.text&.match(/^\w+/)&.to_s)
      end
    end
  end
end
