# frozen_string_literal: true

require "logger"

module Performance::Metrics
  # Utility class to generate and publish a set of metrics for the
  # provided period and date arguments. It delegates the actual
  # generation to PerformancePlatform::Gateway::ActiveUsers and will
  # upload the result in the S3 bucket designated through
  # ENV['S3_METRICS_BUCKET'].
  class DailyMetricSender
    STATS = {
      monthly_rolling_total: Performance::UseCase::MonthlyRollingWindowTotalActiveUsers,
      monthly_rolling_roaming: Performance::UseCase::MonthlyRollingWindowTotalRoamingUsers,
      month_to_date_total: Performance::UseCase::MonthToDateTotalActiveUsers,
      month_to_date_roaming: Performance::UseCase::MonthToDateTotalRoamingUsers,
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

      logger = Logger.new($stdout)
      logger.info(stats)

      S3Publisher.publish "#{@metric}/#{key}", stats
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
