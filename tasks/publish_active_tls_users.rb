require "logger"
require_relative "../lib/performance/metrics"
logger = Logger.new($stdout)

task :publish_active_tls_users, [:date] => :load_env do |_, args|
  args.with_defaults(date: Date.today.to_s)

  logger.info("Creating active TLS user metrics for S3 with #{args[:date]}")

  Performance::Metrics::TlsMetricSender::STATS.each_key do |metric|
    metric_sender = Performance::Metrics::TlsMetricSender.new(date: Date.parse(args[:date]), metric:, logger:)
    logger.info("BEGIN: [#{metric_sender.key}] Fetching and uploading TLS metrics...")

    metric_sender.to_s3
    metric_sender.to_api

    logger.info("END: [#{metric_sender.key}] Done.")
  end
end
