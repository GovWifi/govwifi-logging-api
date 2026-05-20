# frozen_string_literal: true

require_relative "./s3_fake_client"

describe Performance::Metrics::DailyMetricSender do
  let(:today) { Date.today }
  let(:s3_client) { Performance::Metrics.fake_s3_client }

  let(:test_logger) { double("logger", info: nil, warn: nil) }

  subject(:monthly_rolling_total) do
    Performance::Metrics::DailyMetricSender.new(period: "day", date: today, metric: :monthly_rolling_total, logger: test_logger)
  end

  subject(:monthly_rolling_roaming) do
    Performance::Metrics::DailyMetricSender.new(period: "day", date: today, metric: :monthly_rolling_roaming, logger: test_logger)
  end

  subject(:month_to_date_total) do
    Performance::Metrics::DailyMetricSender.new(period: "day", date: today, metric: :month_to_date_total, logger: test_logger)
  end

  subject(:month_to_date_roaming) do
    Performance::Metrics::DailyMetricSender.new(period: "day", date: today, metric: :month_to_date_roaming, logger: test_logger)
  end

  it "defaults to a standard logger writing to $stdout" do
    sender = Performance::Metrics::DailyMetricSender.new(period: "day", date: today, metric: :monthly_rolling_total)
    expect(sender.instance_variable_get(:@logger)).to be_a(Logger)
  end

  let(:monthly_rolling_total_expected_hash) do
    { "metric_name" => "monthly-rolling-window-total-active-users",
      "period" => "day",
      "users" => 0,
      "run_time" => today.to_s,
      "date" => today.to_s }
  end

  let(:monthly_rolling_roaming_expected_hash) do
    { "metric_name" => "monthly-rolling-window-total-roaming-users",
      "period" => "day",
      "users" => 0,
      "run_time" => today.to_s,
      "date" => today.to_s }
  end

  let(:month_to_date_total_expected_hash) do
    { "metric_name" => "month-to-date-total-active-users",
      "period" => "day",
      "users" => 0,
      "run_time" => today.to_s,
      "date" => today.to_s }
  end

  let(:month_to_date_roaming_expected_hash) do
    { "metric_name" => "month-to-date-total-roaming-users",
      "period" => "day",
      "users" => 0,
      "run_time" => today.to_s,
      "date" => today.to_s }
  end

  before do
    ENV["S3_METRICS_BUCKET"] = "stub-bucket"
    DB[:sessions].truncate
    USER_DB[:userdetails].truncate
  end

  it "rejects invalid periods" do
    expect {  Performance::Metrics::DailyMetricSender.new(period: "foo", date: Date.today, metric: :monthly_rolling_total) }
      .to raise_error(ArgumentError)
  end

  it "rejects invalid stats" do
    expect {  Performance::Metrics::DailyMetricSender.new(period: "day", date: Date.today, metric: :foo) }
      .to raise_error(ArgumentError)
  end

  def s3_contents(key)
    contents = s3_client.get_object(bucket: ENV.fetch("S3_METRICS_BUCKET"),
                                    key:)
    JSON.parse(contents.body.read)
  end

  describe "#to_s3" do
    before :each do
      allow(Services).to receive(:s3_client).and_return s3_client
    end

    it "sends 'monthly rolling total users' data to S3" do
      monthly_rolling_total.to_s3
      expect(s3_contents("monthly_rolling_total/monthly_rolling_total-day-#{today}"))
        .to eq(monthly_rolling_total_expected_hash)
    end

    it "sends the 'monthly rolling roaming' data to S3" do
      monthly_rolling_roaming.to_s3
      expect(s3_contents("monthly_rolling_roaming/monthly_rolling_roaming-day-#{today}"))
        .to eq(monthly_rolling_roaming_expected_hash)
    end

    it "sends 'month to date total' data to S3" do
      month_to_date_total.to_s3
      expect(s3_contents("month_to_date_total/month_to_date_total-day-#{today}"))
        .to eq(month_to_date_total_expected_hash)
    end

    it "sends 'month to date roaming' data to S3" do
      month_to_date_roaming.to_s3
      expect(s3_contents("month_to_date_roaming/month_to_date_roaming-day-#{today}"))
        .to eq(month_to_date_roaming_expected_hash)
    end
  end

  let(:monthly_rolling_total_expected_transformed_payload) do
    {
      "name" => "monthly-rolling-window-total-active-users",
      "value" => "0",
      "datetime" => "#{today}T00:00:00Z",
    }
  end

  describe "#to_api" do
    let(:api_endpoint) { "https://metrics.development.wifi.service.gov.uk" }
    let(:expected_api_url) { "https://metrics.development.wifi.service.gov.uk/v1/record" }

    before do
      ENV["METRICS_API_ENDPOINT"] = api_endpoint
      ENV["METRICS_API_BEARER_TOKEN"] = "test-token"
    end

    it "sends 'monthly rolling total users' stats to the metrics API" do
      stub = stub_request(:post, expected_api_url)

      monthly_rolling_total.to_api

      expect(stub).to have_been_requested.once
    end

    it "sends stats to the metrics API" do
      stub = stub_request(:post, expected_api_url)

      monthly_rolling_total.to_api

      expect(stub).to have_been_requested.once
    end

    it "sends the correct stats hash" do
      captured = nil
      stub_request(:post, expected_api_url).with do |req|
        captured = JSON.parse(req.body)
        true
      end

      monthly_rolling_total.to_api

      expect(captured).to eq(monthly_rolling_total_expected_transformed_payload)
    end

    context "when stats are present" do
      before do
        stub_request(:post, expected_api_url).to_return(status: 200, body: "success")
      end

      it "logs that it is contacting the metrics API and that the upload succeeded" do
        expect(test_logger).to receive(:info).with(/Contacting metrics API/)
        expect(test_logger).to receive(:info).with(/Metrics API upload succeeded \(status: 200\)/)
        monthly_rolling_total.to_api
      end
    end

    context "when stats are present but the API request returns a failure status code" do
      before do
        stub_request(:post, expected_api_url).to_return(status: 500, body: "internal error")
      end

      it "logs that it is contacting the API and that the upload failed with status and body" do
        expect(test_logger).to receive(:info).with(/Contacting metrics API/)
        expect(test_logger).to receive(:warn).with(/Metrics API upload failed \(status: 500\): internal error/)
        monthly_rolling_total.to_api
      end
    end

    context "when stats are present but the API request fails due to a connection error" do
      before do
        stub_request(:post, expected_api_url).to_raise(Faraday::ConnectionFailed.new("Connection refused"))
      end

      it "logs that it is contacting the API and that the upload failed due to a connection error" do
        expect(test_logger).to receive(:info).with(/Contacting metrics API/)
        expect(test_logger).to receive(:warn).with(/Metrics API upload failed: connection or other error/)
        monthly_rolling_total.to_api
      end
    end

    context "when stats are nil (no stats to upload)" do
      before do
        allow_any_instance_of(Performance::UseCase::MonthlyRollingWindowTotalActiveUsers)
          .to receive(:fetch_stats).and_return(nil)
      end

      it "logs that there are no stats to upload" do
        expect(test_logger).to receive(:info).with(/No stats to upload/)
        monthly_rolling_total.to_api
      end
    end
  end
end
