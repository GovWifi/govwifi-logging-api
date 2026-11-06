# frozen_string_literal: true

require_relative "./s3_fake_client"

describe Performance::Metrics::PeapMetricMigrator do
  let(:year) { 2026 }
  let(:test_logger) { double("logger", info: nil, warn: nil) }
  let(:s3_client) { Performance::Metrics.fake_s3_client }
  let(:api_endpoint) { "https://metrics.development.wifi.service.gov.uk" }
  let(:export_url) { "#{api_endpoint}/v1/data/export?year=#{year}" }
  let(:record_url) { "#{api_endpoint}/v1/record" }

  subject(:migrator) { described_class.new(year:, logger: test_logger) }

  before do
    ENV["METRICS_API_ENDPOINT"] = api_endpoint
    ENV["METRICS_API_BEARER_TOKEN"] = "test-token"
    ENV["S3_METRICS_BUCKET"] = "stub-bucket"
    allow(Services).to receive(:s3_client).and_return(s3_client)
  end

  def s3_contents(key)
    contents = s3_client.get_object(bucket: ENV.fetch("S3_METRICS_BUCKET"), key:)
    JSON.parse(contents.body.read)
  end

  describe "#execute" do
    context "when rolling and MTD metrics exist for matching dates" do
      let(:exported_records) do
        [
          { "name" => "monthly-rolling-window-total-active-users", "value" => 1000.0, "datetime" => "2026-07-17T00:00:00Z" },
          { "name" => "service-report-active-tls-user-rolling-count", "value" => 250.0, "datetime" => "2026-07-17T00:00:00Z" },
          { "name" => "service-report-peap-unique-users-rolling-count", "value" => 1000.0, "datetime" => "2026-07-17T00:00:00Z" },
          { "name" => "month-to-date-total-active-users", "value" => 400.0, "datetime" => "2026-07-17T00:00:00Z" },
          { "name" => "service-report-active-tls-user-mtd-count", "value" => 120.0, "datetime" => "2026-07-17T00:00:00Z" },
          { "name" => "service-report-peap-unique-users-mtd-count", "value" => 400.0, "datetime" => "2026-07-17T00:00:00Z" },
        ]
      end

      before do
        stub_request(:get, export_url).to_return(status: 200, body: exported_records.to_json)
      end

      it "recalculates PEAP counts as (Active - TLS), updates the Metrics API via PUT, and overwrites S3" do
        updated_payloads = []
        stub_request(:put, record_url)
          .with { |req| updated_payloads << JSON.parse(req.body) }
          .to_return(status: 200, body: '{"message":"Metric updated successfully"}')

        counts = migrator.execute

        expect(counts).to eq({ updated: 2, skipped: 0, failed: 0 })
        expect(updated_payloads).to contain_exactly(
          {
            "name" => "service-report-peap-unique-users-rolling-count",
            "value" => "750",
            "datetime" => "2026-07-17T00:00:00Z",
          },
          {
            "name" => "service-report-peap-unique-users-mtd-count",
            "value" => "280",
            "datetime" => "2026-07-17T00:00:00Z",
          },
        )

        rolling_s3_key = "service-report-peap-unique-users-rolling-count/service-report-peap-unique-users-rolling-count-2026-07-17"
        expect(s3_contents(rolling_s3_key)).to eq(
          "count" => 750,
          "run_time" => "2026-07-17",
          "metric_name" => "service-report-peap-unique-users-rolling-count",
          "period" => "day",
          "date" => "2026-07-17",
        )

        mtd_s3_key = "service-report-peap-unique-users-mtd-count/service-report-peap-unique-users-mtd-count-2026-07-17"
        expect(s3_contents(mtd_s3_key)).to eq(
          "count" => 280,
          "run_time" => "2026-07-17",
          "metric_name" => "service-report-peap-unique-users-mtd-count",
          "period" => "day",
          "date" => "2026-07-17",
        )
      end
    end

    context "when TLS unique users exceed active users on a date" do
      let(:exported_records) do
        [
          { "name" => "monthly-rolling-window-total-active-users", "value" => 10.0, "datetime" => "2026-07-18T00:00:00Z" },
          { "name" => "service-report-active-tls-user-rolling-count", "value" => 25.0, "datetime" => "2026-07-18T00:00:00Z" },
          { "name" => "service-report-peap-unique-users-rolling-count", "value" => 10.0, "datetime" => "2026-07-18T00:00:00Z" },
        ]
      end

      before do
        stub_request(:get, export_url).to_return(status: 200, body: exported_records.to_json)
      end

      it "floors the recalculated PEAP count at 0" do
        captured = nil
        stub_request(:put, record_url)
          .with { |req| captured = JSON.parse(req.body) }
          .to_return(status: 200, body: "updated")

        counts = migrator.execute

        expect(counts).to eq({ updated: 1, skipped: 0, failed: 0 })
        expect(captured["value"]).to eq("0")
      end
    end

    context "when Active Users or TLS Unique Users is missing for a PEAP date" do
      let(:exported_records) do
        [
          { "name" => "monthly-rolling-window-total-active-users", "value" => 100.0, "datetime" => "2026-07-19T00:00:00Z" },
          { "name" => "service-report-peap-unique-users-rolling-count", "value" => 100.0, "datetime" => "2026-07-19T00:00:00Z" },
        ]
      end

      before do
        stub_request(:get, export_url).to_return(status: 200, body: exported_records.to_json)
      end

      it "skips the incomplete date, logs a warning, and does not call PUT" do
        expect(test_logger).to receive(:warn).with(/Skipping migration: missing Active Users or TLS Unique Users record for 2026-07-19/)
        expect(Performance::Metrics::MetricsApiPublisher).not_to receive(:update)

        counts = migrator.execute

        expect(counts).to eq({ updated: 0, skipped: 1, failed: 0 })
      end
    end

    context "when fetching the export from Metrics API fails" do
      before do
        stub_request(:get, export_url).to_return(status: 500, body: "error")
      end

      it "logs a warning and aborts with zero counts" do
        expect(test_logger).to receive(:warn).with("Failed to fetch metrics export for year 2026. Aborting migration.")
        expect(migrator.execute).to eq({ updated: 0, skipped: 0, failed: 0 })
      end
    end

    context "when updating a record via PUT fails with HTTP error or connection error" do
      let(:exported_records) do
        [
          { "name" => "monthly-rolling-window-total-active-users", "value" => 100.0, "datetime" => "2026-07-20T00:00:00Z" },
          { "name" => "service-report-active-tls-user-rolling-count", "value" => 20.0, "datetime" => "2026-07-20T00:00:00Z" },
          { "name" => "service-report-peap-unique-users-rolling-count", "value" => 100.0, "datetime" => "2026-07-20T00:00:00Z" },
          { "name" => "month-to-date-total-active-users", "value" => 50.0, "datetime" => "2026-07-20T00:00:00Z" },
          { "name" => "service-report-active-tls-user-mtd-count", "value" => 10.0, "datetime" => "2026-07-20T00:00:00Z" },
          { "name" => "service-report-peap-unique-users-mtd-count", "value" => 50.0, "datetime" => "2026-07-20T00:00:00Z" },
        ]
      end

      before do
        stub_request(:get, export_url).to_return(status: 200, body: exported_records.to_json)
        stub_request(:put, record_url)
          .to_return(status: 500, body: "server error")
          .then
          .to_raise(Faraday::ConnectionFailed.new("Connection refused"))
      end

      it "logs warnings, does not write to S3, and increments failed count" do
        expect(test_logger).to receive(:warn).with(/Migration failed \(status: 500\): server error/)
        expect(test_logger).to receive(:warn).with(/Migration failed: connection or other error/)
        expect(Services).not_to receive(:s3_client)

        counts = migrator.execute

        expect(counts).to eq({ updated: 0, skipped: 0, failed: 2 })
      end
    end
  end
end
