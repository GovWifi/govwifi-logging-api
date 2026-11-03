# frozen_string_literal: true

module Performance::Metrics
  class PeapMetricMigrator
    MIGRATION_CONFIGS = [
      {
        peap_metric: "service-report-peap-unique-users-rolling-count",
        active_metric: "monthly-rolling-window-total-active-users",
        tls_metric: "service-report-active-tls-user-rolling-count",
      },
      {
        peap_metric: "service-report-peap-unique-users-mtd-count",
        active_metric: "month-to-date-total-active-users",
        tls_metric: "service-report-active-tls-user-mtd-count",
      },
    ].freeze

    def initialize(year: Date.today.year, logger: Logger.new($stdout))
      @year = year
      @logger = logger
    end

    def execute
      @logger.info("Fetching metrics export for year #{@year}...")
      records = MetricsApiPublisher.fetch_export(year: @year)

      if records.nil?
        @logger.warn("Failed to fetch metrics export for year #{@year}. Aborting migration.")
        return { updated: 0, skipped: 0, failed: 0 }
      end

      indexed = index_records_by_name_and_date(records)
      counts = { updated: 0, skipped: 0, failed: 0 }

      MIGRATION_CONFIGS.each do |config|
        migrate_metric_series(config, indexed, counts)
      end

      @logger.info(
        "PEAP metrics migration complete for #{@year}: " \
        "#{counts[:updated]} updated, #{counts[:skipped]} skipped, #{counts[:failed]} failed.",
      )
      counts
    end

  private

    def index_records_by_name_and_date(records)
      indexed = Hash.new { |h, k| h[k] = {} }
      records.each do |record|
        name = record["name"]
        datetime = record["datetime"].to_s
        date = datetime[0, 10]
        next if name.nil? || date.empty?

        indexed[name][date] = record
      end
      indexed
    end

    def migrate_metric_series(config, indexed, counts)
      peap_metric = config[:peap_metric]
      active_by_date = indexed[config[:active_metric]]
      tls_by_date = indexed[config[:tls_metric]]
      peap_by_date = indexed[peap_metric]

      peap_by_date.each do |date, peap_record|
        active_record = active_by_date[date]
        tls_record = tls_by_date[date]

        if active_record.nil? || tls_record.nil?
          @logger.warn("[#{peap_metric}-#{date}] Skipping migration: missing Active Users or TLS Unique Users record for #{date}.")
          counts[:skipped] += 1
          next
        end

        new_count = [active_record["value"].to_f.round - tls_record["value"].to_f.round, 0].max
        old_count = peap_record["value"].to_f.round
        key = "#{peap_metric}-#{date}"

        @logger.info(
          "[#{key}] Updating count from #{old_count} to #{new_count} " \
          "(active: #{active_record['value'].to_f.round}, tls: #{tls_record['value'].to_f.round})...",
        )

        api_stats = {
          count: new_count,
          run_time: peap_record["datetime"] || date,
          metric_name: peap_metric,
          period: "day",
          date:,
        }

        response = MetricsApiPublisher.update(api_stats)
        if response&.success?
          update_s3(peap_metric, date, new_count)
          @logger.info("[#{key}] Migration succeeded (status: #{response.status}).")
          counts[:updated] += 1
        elsif response
          @logger.warn("[#{key}] Migration failed (status: #{response.status}): #{response.body}")
          counts[:failed] += 1
        else
          @logger.warn("[#{key}] Migration failed: connection or other error.")
          counts[:failed] += 1
        end
      end
    end

    def update_s3(peap_metric, date, new_count)
      return if ENV["S3_METRICS_BUCKET"].to_s.strip.empty?

      s3_stats = {
        count: new_count,
        run_time: date,
        metric_name: peap_metric,
        period: "day",
        date:,
      }
      S3Publisher.publish("#{peap_metric}/#{peap_metric}-#{date}", s3_stats)
    end
  end
end
