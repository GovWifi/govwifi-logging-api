require "logger"
require "./lib/performance/metrics"
logger = Logger.new($stdout)

task :publish_daily_total_metrics, [:date] => %i[load_env synchronize_ip_locations] do |_, args|
  args.with_defaults(date: Date.today.to_s)

  logger.info("Creating daily total metrics for S3 with #{args[:date]}")

  Performance::Metrics::DailyMetricSender::STATS.each_key do |metrics|
    metric_sender = Performance::Metrics::DailyMetricSender.new(period: "day", date: Date.parse(args[:date]), metric: metrics)
    logger.info("BEGIN: [#{metric_sender.key}] Fetching and uploading metrics...")

    metric_sender.to_s3
    metric_sender.to_api

    logger.info("END: [#{metric_sender.key}] Done.")
  end
end
