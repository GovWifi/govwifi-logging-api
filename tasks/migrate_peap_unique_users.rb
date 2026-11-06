require "logger"
require_relative "../lib/performance/metrics"
logger = Logger.new($stdout)

task :migrate_peap_unique_users, [:year] => :load_env do |_, args|
  args.with_defaults(year: Date.today.year.to_s)
  year = Integer(args[:year])

  logger.info("BEGIN: Migrating PEAP unique user metrics for year #{year}...")
  Performance::Metrics::PeapMetricMigrator.new(year:, logger:).execute
  logger.info("END: Migrating PEAP unique user metrics for year #{year} done.")
end
