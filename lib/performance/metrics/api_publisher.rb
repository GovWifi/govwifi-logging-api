# frozen_string_literal: true

require "faraday"
require "json"

module Performance::Metrics
  class ApiPublisher
    def self.publish(stats)
      connection.post do |req|
        req.headers["Authorization"] = "Bearer #{ENV.fetch('METRICS_API_BEARER_TOKEN')}"
        req.headers["Content-Type"] = "application/json"
        req.body = stats.to_json
      end
    end

    def self.connection
      @connection ||= Faraday.new(url: ENV.fetch("METRICS_API_ENDPOINT"))
    end
  end
end
