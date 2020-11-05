require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.default_cassette_options = {
    clean_outdated_http_interactions: true,
    re_record_interval: 7 * 24 * 3600,
    record: :once,
  }
  config.hook_into :webmock
end
