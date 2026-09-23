# frozen_string_literal: true

require "rake"

describe "publish_active_tls_users rake task" do
  before do
    Rake::Task.define_task(:load_env) unless Rake::Task.task_defined?(:load_env)
    load File.expand_path("../../tasks/publish_active_tls_users.rb", __dir__)
  end

  it "calls to_s3 and to_api on TlsMetricSender for each metric" do
    sender_double = instance_double(Performance::Metrics::TlsMetricSender, key: "test-key", to_s3: nil, to_api: nil)
    expect(Performance::Metrics::TlsMetricSender).to receive(:new).with(
      date: Date.parse("2026-07-17"),
      metric: :monthly_rolling_tls,
      logger: anything,
    ).and_return(sender_double)
    expect(Performance::Metrics::TlsMetricSender).to receive(:new).with(
      date: Date.parse("2026-07-17"),
      metric: :month_to_date_tls,
      logger: anything,
    ).and_return(sender_double)

    expect(sender_double).to receive(:to_s3).twice
    expect(sender_double).to receive(:to_api).twice

    Rake::Task["publish_active_tls_users"].reenable
    Rake::Task["publish_active_tls_users"].invoke("2026-07-17")
  end

  describe "integration with publish_daily_total_metrics" do
    before do
      Rake::Task.define_task(:synchronize_ip_locations) unless Rake::Task.task_defined?(:synchronize_ip_locations)
      load File.expand_path("../../tasks/recover_active_users.rb", __dir__)
    end

    it "invokes publish_active_tls_users when publish_daily_total_metrics runs" do
      daily_sender_double = instance_double(Performance::Metrics::DailyMetricSender, key: "daily-key", to_s3: nil, to_api: nil)
      allow(Performance::Metrics::DailyMetricSender).to receive(:new).and_return(daily_sender_double)

      tls_task = Rake::Task["publish_active_tls_users"]
      expect(tls_task).to receive(:execute)

      Rake::Task["publish_daily_total_metrics"].reenable
      Rake::Task["publish_daily_total_metrics"].invoke("2026-07-17")
    end
  end
end
