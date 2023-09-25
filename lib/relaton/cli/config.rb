module Relaton
  module Cli
    module Config
      include RelatonBib::Config
    end
    extend Config

    class Configuration < RelatonBib::Configuration
      PROGNAME = "relaton-cli".freeze
    end
  end
end
