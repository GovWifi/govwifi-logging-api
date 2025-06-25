# frozen_string_literal: true

module Performance::Metrics
  # Utility class to generate and publish a set of metrics for the
  # provided period and date arguments. It delegates the actual
  # generation to PerformancePlatform::Gateway::ActiveUsers and will
  # upload the result in the S3 bucket designated through
  # ENV['S3_METRICS_BUCKET'].
  class MetricSender
    STATS = {
      active_users: Performance::UseCase::ActiveUsers,
      completion_rate: Performance::UseCase::CompletionRate,
      inactive_users: Performance::UseCase::NewUsers,
      roaming_users: Performance::UseCase::RoamingUsers,
      volumetrics: Performance::UseCase::Volumetrics,
      user_devices: Performance::UseCase::UserDevices,
    }.freeze

    def initialize(metric:, period: :daily, date: Date.today)
      raise ArgumentError unless PERIODS.values.include? period
      raise ArgumentError unless STATS.keys.include? metric

      @metric = metric
      @period = period
      @date = date
    end

    def to_s3
      return if stats.nil?

      S3Publisher.publish "#{@metric}/#{key}", stats
    end

    def to_elasticsearch
      return if stats.nil?

      Performance::Gateway::Elasticsearch.new(ELASTICSEARCH_INDEX).write(key, stats)
    end

    def key
      "#{@metric}-#{@period}-#{@date}"
    end

  private

    def stats
      @stats ||= STATS[@metric].new(period: @period, date: @date).fetch_stats
    end
  end
end
