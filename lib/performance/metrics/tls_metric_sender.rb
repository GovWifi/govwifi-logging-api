# frozen_string_literal: true

module Performance::Metrics
  class TlsMetricSender
    STATS = {
      monthly_rolling_tls: Performance::UseCase::MonthlyRollingWindowActiveTlsUsers,
      month_to_date_tls: Performance::UseCase::MonthToDateActiveTlsUsers,
    }.freeze

    METRIC_NAMES = {
      monthly_rolling_tls: "service-report-active-tls-user-rolling-count",
      month_to_date_tls: "service-report-active-tls-user-mtd-count",
    }.freeze

    def initialize(metric:, period: "day", date: Date.today, logger: Logger.new($stdout))
      raise ArgumentError unless STATS.key?(metric)

      @metric = metric
      @period = period
      @date = date
      @logger = logger
    end

    def to_s3
      return if stats.nil?

      S3Publisher.publish "#{folder}/#{filename}", stats
    end

    def to_api
      if stats.nil?
        @logger.info("[#{key}] No stats to upload.")
        return
      end

      @logger.info("[#{key}] Contacting metrics API...")
      response = MetricsApiPublisher.publish(stats)

      if response&.success?
        @logger.info("[#{key}] Metrics API upload succeeded (status: #{response.status}).")
      elsif response
        @logger.warn("[#{key}] Metrics API upload failed (status: #{response.status}): #{response.body}")
      else
        @logger.warn("[#{key}] Metrics API upload failed: connection or other error.")
      end
    end

    def folder
      METRIC_NAMES.fetch(@metric)
    end

    def filename
      "#{folder}-#{@date}"
    end

    def key
      filename
    end

  private

    def stats
      @stats ||= STATS[@metric].new(period: @period, date: @date).fetch_stats
    end
  end
end
