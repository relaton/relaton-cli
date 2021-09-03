module Relaton
  module Cli
    module DataFetcher
      def fetch(source, options)
        processor = Relaton::Registry.instance.find_processor_by_dataset source
        processor.fetch_data source, options
      end

      extend DataFetcher
    end
  end
end
