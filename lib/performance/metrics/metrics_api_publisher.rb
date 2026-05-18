# frozen_string_literal: true

require "faraday"
require "json"
require "logger"

module Performance::Metrics
  class MetricsApiPublisher
    def self.publish(stats)
      connection.post do |req|
        req.headers["Authorization"] = "Bearer #{ENV.fetch('METRICS_API_BEARER_TOKEN')}"
        req.headers["Content-Type"] = "application/json"
        req.body = stats.to_json
      end
    rescue Faraday::Error => e
      logger.warn("Metrics API request failed: #{e.message} (endpoint: #{ENV.fetch('METRICS_API_ENDPOINT', 'unknown')})")
    end

    def self.connection
      @connection ||= Faraday.new(url: ENV.fetch("METRICS_API_ENDPOINT"))
    end

    class << self
      attr_writer :logger

      def logger
        @logger ||= Logger.new($stdout)
      end
    end
  end
end
