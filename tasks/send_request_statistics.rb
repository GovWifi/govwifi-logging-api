# frozen_string_literal: true

require "logger"

desc "Send request statistics (Elasticsearch)"
task send_request_statistics: :load_env do
  Performance::Metrics::RequestStatsSender.new.send_data
end
