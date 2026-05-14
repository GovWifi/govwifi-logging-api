# frozen_string_literal: true

require_relative "./s3_fake_client"

describe Performance::Metrics::DailyMetricSender do
  let(:today) { Date.today }
  let(:s3_client) { Performance::Metrics.fake_s3_client }

  subject(:monthly_rolling_total) do
    Performance::Metrics::DailyMetricSender.new(period: "day", date: today, metric: :monthly_rolling_total)
  end

  subject(:monthly_rolling_roaming) do
    Performance::Metrics::DailyMetricSender.new(period: "day", date: today, metric: :monthly_rolling_roaming)
  end

  subject(:month_to_date_total) do
    Performance::Metrics::DailyMetricSender.new(period: "day", date: today, metric: :month_to_date_total)
  end

  subject(:month_to_date_roaming) do
    Performance::Metrics::DailyMetricSender.new(period: "day", date: today, metric: :month_to_date_roaming)
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

  describe "#to_api" do
    let(:api_endpoint) { "https://metrics.development.wifi.service.gov.uk/v1/record" }

    before do
      ENV["METRICS_API_ENDPOINT"] = api_endpoint
      ENV["METRICS_API_BEARER_TOKEN"] = "test-token"
    end

    it "sends 'monthly rolling total users' stats to the metrics API" do
      stub = stub_request(:post, api_endpoint)

      monthly_rolling_total.to_api

      expect(stub).to have_been_requested.once
    end

    it "sends stats to the metrics API" do
      stub = stub_request(:post, api_endpoint)

      monthly_rolling_total.to_api

      expect(stub).to have_been_requested.once
    end

    it "sends the correct stats hash" do
      captured = nil
      stub_request(:post, api_endpoint).with { |req| captured = JSON.parse(req.body); true }

      monthly_rolling_total.to_api

      expect(captured).to eq(monthly_rolling_total_expected_hash)
    end
  end
end
