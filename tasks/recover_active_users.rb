require "logger"
require "date"

logger = Logger.new($stdout)

desc "Publish month to date total active users (daily derived)"
task publish_month_to_date_total_active_users_metrics: [:load_env] do
  logger.info("Creating 'publish_month_to_date_total_active_metrics' metrics for S3 with today's date")

  def metric
    "month_to_date_total_active_users"
  end

  def key
    "month_to_date_total_active-day-#{Date.today}"
  end

  def to_s3
    return if stats.nil?

    Performance::Metrics::S3Publisher.publish("#{metric}/#{key}", stats)
  end

  def stats
    Performance::UseCase::MonthToDateTotalActiveUsers.new.fetch_stats
  end

  logger.info("[#{key}] Fetching and uploading metrics...")
  to_s3
  logger.info("[#{key}] Done.")
end

# Add three more tasks here... or create three additional standalone task files?
# Do I create a new hash containing these daily tasks and loop over them like the
# metric_sender does for its STATS? ... and therefore create a class definition
# within this file.
