# frozen_string_literal: true

require_relative "./s3_fake_client"

describe Performance::Metrics::TlsMetricSender do
  let(:today) { Date.today }
  let(:s3_client) { Performance::Metrics.fake_s3_client }
  let(:test_logger) { double("logger", info: nil, warn: nil) }

  subject(:monthly_rolling_tls) do
    described_class.new(period: "day", date: today, metric: :monthly_rolling_tls, logger: test_logger)
  end

  subject(:month_to_date_tls) do
    described_class.new(period: "day", date: today, metric: :month_to_date_tls, logger: test_logger)
  end

  let(:monthly_rolling_expected_hash) do
    {
      "count" => 0,
      "run_time" => today.to_s,
      "metric_name" => "service-report-active-tls-user-rolling-count",
      "period" => "day",
      "date" => today.to_s,
    }
  end

  let(:month_to_date_expected_hash) do
    {
      "count" => 0,
      "run_time" => today.to_s,
      "metric_name" => "service-report-active-tls-user-mtd-count",
      "period" => "day",
      "date" => today.to_s,
    }
  end

  before do
    ENV["S3_METRICS_BUCKET"] = "stub-bucket"
    DB[:sessions].truncate
  end

  it "defaults to a standard logger writing to $stdout" do
    sender = described_class.new(period: "day", date: today, metric: :monthly_rolling_tls)
    expect(sender.instance_variable_get(:@logger)).to be_a(Logger)
  end

  it "rejects invalid metric keys" do
    expect { described_class.new(period: "day", date: today, metric: :invalid_metric) }
      .to raise_error(ArgumentError)
  end

  def s3_contents(key)
    contents = s3_client.get_object(bucket: ENV.fetch("S3_METRICS_BUCKET"), key:)
    JSON.parse(contents.body.read)
  end

  describe "#to_s3" do
    before do
      allow(Services).to receive(:s3_client).and_return s3_client
    end

    it "sends 'monthly rolling TLS users' data to S3 in the expected folder and filename" do
      monthly_rolling_tls.to_s3
      key = "service-report-active-tls-user-rolling-count/service-report-active-tls-user-rolling-count-#{today}"
      expect(s3_contents(key)).to eq(monthly_rolling_expected_hash)
    end

    it "sends 'month to date TLS users' data to S3 in the expected folder and filename" do
      month_to_date_tls.to_s3
      key = "service-report-active-tls-user-mtd-count/service-report-active-tls-user-mtd-count-#{today}"
      expect(s3_contents(key)).to eq(month_to_date_expected_hash)
    end

    context "when stats are nil" do
      before do
        allow_any_instance_of(Performance::UseCase::MonthlyRollingWindowActiveTlsUsers)
          .to receive(:fetch_stats).and_return(nil)
      end

      it "does not write to S3" do
        expect(Services).not_to receive(:s3_client)
        monthly_rolling_tls.to_s3
      end
    end
  end

  describe "#to_api" do
    let(:api_endpoint) { "https://metrics.development.wifi.service.gov.uk" }
    let(:expected_api_url) { "https://metrics.development.wifi.service.gov.uk/v1/record" }

    before do
      ENV["METRICS_API_ENDPOINT"] = api_endpoint
      ENV["METRICS_API_BEARER_TOKEN"] = "test-token"
    end

    let(:monthly_rolling_expected_api_payload) do
      {
        "name" => "service-report-active-tls-user-rolling-count",
        "value" => "0",
        "datetime" => "#{today}T00:00:00Z",
      }
    end

    let(:month_to_date_expected_api_payload) do
      {
        "name" => "service-report-active-tls-user-mtd-count",
        "value" => "0",
        "datetime" => "#{today}T00:00:00Z",
      }
    end

    it "sends rolling TLS stats payload to the metrics API" do
      captured = nil
      stub_request(:post, expected_api_url).with do |req|
        captured = JSON.parse(req.body)
        true
      end

      monthly_rolling_tls.to_api

      expect(captured).to eq(monthly_rolling_expected_api_payload)
    end

    it "sends MTD TLS stats payload to the metrics API" do
      captured = nil
      stub_request(:post, expected_api_url).with do |req|
        captured = JSON.parse(req.body)
        true
      end

      month_to_date_tls.to_api

      expect(captured).to eq(month_to_date_expected_api_payload)
    end

    context "when API request succeeds" do
      before do
        stub_request(:post, expected_api_url).to_return(status: 201, body: "created")
      end

      it "logs contacting and success messages" do
        expect(test_logger).to receive(:info).with(/Contacting metrics API/)
        expect(test_logger).to receive(:info).with(/Metrics API upload succeeded \(status: 201\)/)
        monthly_rolling_tls.to_api
      end
    end

    context "when API request returns an error status code" do
      before do
        stub_request(:post, expected_api_url).to_return(status: 500, body: "internal error")
      end

      it "logs contacting and warning messages" do
        expect(test_logger).to receive(:info).with(/Contacting metrics API/)
        expect(test_logger).to receive(:warn).with(/Metrics API upload failed \(status: 500\): internal error/)
        monthly_rolling_tls.to_api
      end
    end

    context "when API request fails with a connection error" do
      before do
        stub_request(:post, expected_api_url).to_raise(Faraday::ConnectionFailed.new("Connection refused"))
      end

      it "logs contacting and connection error warning" do
        expect(test_logger).to receive(:info).with(/Contacting metrics API/)
        expect(test_logger).to receive(:warn).with(/Metrics API upload failed: connection or other error/)
        monthly_rolling_tls.to_api
      end
    end

    context "when stats are nil" do
      before do
        allow_any_instance_of(Performance::UseCase::MonthlyRollingWindowActiveTlsUsers)
          .to receive(:fetch_stats).and_return(nil)
      end

      it "logs that there are no stats to upload and does not call API" do
        expect(test_logger).to receive(:info).with(/No stats to upload/)
        expect(Performance::Metrics::MetricsApiPublisher).not_to receive(:publish)
        monthly_rolling_tls.to_api
      end
    end
  end
end
