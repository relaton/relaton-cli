require "relaton"
require_relative "bibcollection"
require_relative "bibdata"
require_relative "cli/xml_to_html_renderer"
require_relative "cli/command"
require "thor"

module Relaton
  module Cli
    def self.start(arguments)
      Relaton::Cli::Command.start(arguments)
    end

    # Temporary: Load Supported Gems
    #
    # Based on current setup, looks like we need to initiate a db
    # instance to register all of it's supported processor  backends.
    # So let's put this here for now & as soon as we've some alternative
    # then we can optimize this later.
    #
    def self.relaton
      @relaton ||= Relaton::Db.new("#{Dir.home}/.relaton-bib.pstore", nil)
    end
  end
end
