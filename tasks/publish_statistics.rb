# frozen_string_literal: true

require "logger"
require "./lib/performance/metrics"

logger = Logger.new($stdout)

desc "Synchronize IP locations"
task synchronize_ip_locations: :load_env do
  Performance::Metrics::IPSynchronizer.new.execute
end

Performance::Metrics::PERIODS.each do |adverbial, period|
  name = "publish_#{adverbial}_metrics".to_sym
  dependent_tasks = adverbial == :daily ? %i[load_env synchronize_ip_locations] : [:load_env]

  desc "Publish #{adverbial} metrics to S3 and Elasticsearch"
  task name, [:date] => dependent_tasks do |_, args|
    args.with_defaults(date: Date.today.to_s)

    logger.info("Creating #{adverbial} metrics for S3 with #{args[:date]}")

    Performance::Metrics::MetricSender::STATS.each_key do |metrics|
      metric_sender = Performance::Metrics::MetricSender.new(period:, date: Date.parse(args[:date]), metric: metrics)
      logger.info("[#{metric_sender.key}] Fetching and uploading metrics...")

      metric_sender.to_s3
      metric_sender.to_elasticsearch

      logger.info("[#{metric_sender.key}] Done.")
    end
  end
end
