require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.default_cassette_options = {
    clean_outdated_http_interactions: true,
    re_record_interval: nil, # deliberate re-record only; auto-rerecord made CI hit unreachable live hosts
    record: :once,
  }
  config.hook_into :webmock
end
