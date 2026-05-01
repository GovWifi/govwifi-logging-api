require "logger"
require "./lib/performance/metrics"
logger = Logger.new($stdout)

task synchronize_ip_locations: :load_env do
  Performance::Metrics::IPSynchronizer.new.execute
end

PERIOD = Performance::Metrics::PERIODS.select { |adverbial, _period| adverbial == :daily }
PERIOD.each do |adverbial, period|
  name = "publish_#{adverbial}_total_metrics".to_sym

  dependent_tasks = adverbial == :daily ? %i[load_env synchronize_ip_locations] : [:load_env]

  task name, [:date] => dependent_tasks do |_, args|
    args.with_defaults(date: Date.today.to_s)

    logger.info("Creating #{adverbial} total metrics for S3 with #{args[:date]}")

    Performance::Metrics::DailyMetricSender::STATS.each_key do |metrics|
      metric_sender = Performance::Metrics::DailyMetricSender.new(period:, date: Date.parse(args[:date]), metric: metrics)
      logger.info("BEGIN: [#{metric_sender.key}] Fetching and uploading metrics...")

      metric_sender.to_s3

      logger.info("END: [#{metric_sender.key}] Done.")
    end
  end
end
