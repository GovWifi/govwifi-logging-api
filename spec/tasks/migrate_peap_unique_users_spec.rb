# frozen_string_literal: true

require "rake"

describe "migrate_peap_unique_users rake task" do
  before do
    Rake::Task.define_task(:load_env) unless Rake::Task.task_defined?(:load_env)
    Rake::Task["migrate_peap_unique_users"]&.clear if Rake::Task.task_defined?("migrate_peap_unique_users")
    load File.expand_path("../../tasks/migrate_peap_unique_users.rb", __dir__)
  end

  it "runs PeapMetricMigrator for the provided year" do
    migrator_double = instance_double(Performance::Metrics::PeapMetricMigrator, execute: { updated: 2, skipped: 0, failed: 0 })
    expect(Performance::Metrics::PeapMetricMigrator).to receive(:new).with(
      year: 2026,
      logger: anything,
    ).and_return(migrator_double)
    expect(migrator_double).to receive(:execute)

    Rake::Task["migrate_peap_unique_users"].reenable
    Rake::Task["migrate_peap_unique_users"].invoke("2026")
  end

  it "defaults to the current calendar year when no year argument is provided" do
    migrator_double = instance_double(Performance::Metrics::PeapMetricMigrator, execute: { updated: 0, skipped: 0, failed: 0 })
    expect(Performance::Metrics::PeapMetricMigrator).to receive(:new).with(
      year: Date.today.year,
      logger: anything,
    ).and_return(migrator_double)
    expect(migrator_double).to receive(:execute)

    Rake::Task["migrate_peap_unique_users"].reenable
    Rake::Task["migrate_peap_unique_users"].invoke
  end

  it "raises ArgumentError when given an invalid non-integer year" do
    Rake::Task["migrate_peap_unique_users"].reenable
    expect { Rake::Task["migrate_peap_unique_users"].invoke("not-a-year") }.to raise_error(ArgumentError)
  end
end
