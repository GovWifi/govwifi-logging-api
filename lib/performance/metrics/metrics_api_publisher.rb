# frozen_string_literal: true

require "faraday"
require "json"
require "logger"

module Performance::Metrics
  class MetricsApiPublisher
    def self.publish(stats)
      return unless stats

      payload = build_payload(stats)

      connection.post("v1/record") do |req|
        req.headers["Authorization"] = "Bearer #{ENV.fetch('METRICS_API_BEARER_TOKEN')}"
        req.headers["Content-Type"] = "application/json"
        req.body = payload.to_json
      end
    rescue Faraday::Error => e
      logger.warn("Metrics API request failed: #{e.message} (endpoint: #{ENV.fetch('METRICS_API_ENDPOINT', 'unknown')})")
      nil
    end

    def self.update(stats)
      return unless stats

      payload = build_payload(stats)

      connection.put("v1/record") do |req|
        req.headers["Authorization"] = "Bearer #{ENV.fetch('METRICS_API_BEARER_TOKEN')}"
        req.headers["Content-Type"] = "application/json"
        req.body = payload.to_json
      end
    rescue Faraday::Error => e
      logger.warn("Metrics API update request failed: #{e.message} (endpoint: #{ENV.fetch('METRICS_API_ENDPOINT', 'unknown')})")
      nil
    end

    def self.fetch_export(year: Date.today.year)
      response = connection.get("v1/data/export", { year: year }) do |req|
        req.headers["Authorization"] = "Bearer #{ENV.fetch('METRICS_API_BEARER_TOKEN')}"
      end

      unless response&.success?
        status = response ? response.status : "unknown"
        logger.warn("Metrics API export failed (status: #{status}): #{response&.body}")
        return nil
      end

      JSON.parse(response.body)
    rescue Faraday::Error, JSON::ParserError => e
      logger.warn("Metrics API export request failed: #{e.message} (endpoint: #{ENV.fetch('METRICS_API_ENDPOINT', 'unknown')})")
      nil
    end

    def self.build_payload(stats)
      stringified_stats = stats.transform_keys(&:to_s)
      datetime_val = stringified_stats["run_time"]
      if datetime_val
        if datetime_val.match?(/\A\d{4}-\d{2}-\d{2}\z/)
          datetime_val = "#{datetime_val}T00:00:00Z"
        elsif !datetime_val.end_with?("Z")
          datetime_val = "#{datetime_val}Z"
        end
      end

      value_val = (stringified_stats["value"] || stringified_stats["count"] || stringified_stats["users"])&.to_s

      {
        "name" => stringified_stats["metric_name"],
        "value" => value_val,
        "datetime" => datetime_val,
      }
    end
    private_class_method :build_payload

    def self.connection
      base_url = ENV.fetch("METRICS_API_ENDPOINT").chomp("/")
      if @connection && @connection.url_prefix.to_s.chomp("/") == base_url
        @connection
      else
        @connection = Faraday.new(url: base_url)
      end
    end

    class << self
      attr_writer :logger

      def logger
        @logger ||= Logger.new($stdout)
      end
    end
  end
end
