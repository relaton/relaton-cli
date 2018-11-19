require "thor"
require "relaton"
require_relative "cli/command"

module Relaton
  module Cli
    def self.start(arguments)
      Relaton::Cli::Command.start(arguments)
    end

    # Relaton
    #
    # Based on current setup, we need to initiate a Db instance to
    # register all of it's supported processor backends. To make it
    # easier we have added it as a class method so we can use this
    # whenever necessary.
    #
    def self.relaton
      @relaton ||= Relaton::Db.new("#{Dir.home}/.relaton/cache", nil)
    end
  end
end
