module Relaton
  module Cli
    module Util
      extend RelatonBib::Util

      def self.logger
        Relaton::Cli.configuration.logger
      end
    end
  end
end
