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
  end
end
