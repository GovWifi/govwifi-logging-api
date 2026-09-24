require "logger"
require_relative "../lib/performance/metrics"
logger = Logger.new($stdout)

task :publish_peap_unique_users, [:date] => :load_env do |_, args|
  args.with_defaults(date: Date.today.to_s)

  logger.info("Creating PEAP unique user metrics for S3 with #{args[:date]}")

  Performance::Metrics::PeapMetricSender::STATS.each_key do |metric|
    metric_sender = Performance::Metrics::PeapMetricSender.new(date: Date.parse(args[:date]), metric:, logger:)
    logger.info("BEGIN: [#{metric_sender.key}] Fetching and uploading PEAP metrics...")

    metric_sender.to_s3
    metric_sender.to_api

    logger.info("END: [#{metric_sender.key}] Done.")
  end
end
