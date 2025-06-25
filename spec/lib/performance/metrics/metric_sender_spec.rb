# frozen_string_literal: true

require_relative "./s3_fake_client"

describe Performance::Metrics::MetricSender do
  let(:today) { Date.today }
  let(:s3_client) { Performance::Metrics.fake_s3_client }
  let(:elasticsearch_client) { spy }

  subject(:active_users) do
    Performance::Metrics::MetricSender.new(period: "week", date: today, metric: :active_users)
  end

  subject(:completion_rate) do
    Performance::Metrics::MetricSender.new(period: "week", date: today, metric: :completion_rate)
  end

  subject(:roaming_users) do
    Performance::Metrics::MetricSender.new(period: "week", date: today, metric: :roaming_users)
  end

  subject(:volumetrics) do
    Performance::Metrics::MetricSender.new(period: "week", date: today, metric: :volumetrics)
  end

  subject(:user_devices) do
    Performance::Metrics::MetricSender.new(period: "week", date: today, metric: :user_devices)
  end

  let(:user_devices_expected_hash) do
    { "metric_name" => "user-devices",
      "period" => "week",
      "devices" => nil,
      "date" => today.to_s }
  end

  let(:active_users_expected_hash) do
    { "metric_name" => "active-users",
      "period" => "week",
      "users" => 0,
      "date" => today.to_s }
  end

  let(:completion_rate_expected_hash) do
    {
      "metric_name" => "completion-rate",
      "period" => "week",
      "all_registered" => 0,
      "all_logged_in" => 0,
      "sms_registered" => 0,
      "sms_logged_in" => 0,
      "email_registered" => 0,
      "email_logged_in" => 0,
      "sponsor_registered" => 0,
      "sponsor_logged_in" => 0,
      "cumulative_all_registered" => 0,
      "cumulative_all_logged_in" => 0,
      "cumulative_sms_registered" => 0,
      "cumulative_sms_logged_in" => 0,
      "cumulative_email_registered" => 0,
      "cumulative_email_logged_in" => 0,
      "cumulative_sponsor_registered" => 0,
      "cumulative_sponsor_logged_in" => 0,
      "date" => today.to_s,
    }
  end

  let(:roaming_users_expected_hash) do
    { "active" => 0,
      "cba" => 0,
      "metric_name" => "roaming-users",
      "period" => "week",
      "roaming" => 0,
      "date" => today.to_s }
  end

  let(:volumetrics_expected_hash) do
    {
      "period_before" => 0,
      "cumulative" => 0,
      "sms_period_before" => 0,
      "sms_cumulative" => 0,
      "metric_name" => "volumetrics",
      "period" => "week",
      "email_period_before" => 0,
      "email_cumulative" => 0,
      "sponsored_cumulative" => 0,
      "sponsored_period_before" => 0,
      "date" => today.to_s,
    }
  end

  before do
    ENV["S3_METRICS_BUCKET"] = "stub-bucket"
    DB[:sessions].truncate
    USER_DB[:userdetails].truncate
  end

  it "rejects invalid periods" do
    expect {  Performance::Metrics::MetricSender.new(period: "foo", date: Date.today, metric: :active_users) }
      .to raise_error(ArgumentError)
  end

  it "rejects invalid stats" do
    expect {  Performance::Metrics::MetricSender.new(period: "week", date: Date.today, metric: :foo) }
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
    it "sends active users data to S3" do
      active_users.to_s3
      expect(s3_contents("active_users/active_users-week-#{today}"))
        .to eq(active_users_expected_hash)
    end
    it "sends the completion rate data to S3" do
      completion_rate.to_s3
      expect(s3_contents("completion_rate/completion_rate-week-#{today}"))
        .to eq(completion_rate_expected_hash)
    end
    it "sends roaming users data to S3" do
      roaming_users.to_s3
      expect(s3_contents("roaming_users/roaming_users-week-#{today}"))
        .to eq({ "active" => 0, "cba" => 0, "metric_name" => "roaming-users", "period" => "week", "roaming" => 0, "date" => today.to_s })
    end
    it "sends user devices data to S3" do
      user_devices.to_s3
      expect(s3_contents("user_devices/user_devices-week-#{today}"))
        .to eq(user_devices_expected_hash)
    end
    it "sends volumetrics data to S3" do
      volumetrics.to_s3
      expect(s3_contents("volumetrics/volumetrics-week-#{today}"))
        .to eq(volumetrics_expected_hash)
    end
  end

  describe "#to_elasticsearch" do
    before :each do
      allow(Services).to receive(:elasticsearch_client).and_return elasticsearch_client
    end
    it "indexes active users data into Elasticsearch" do
      active_users.to_elasticsearch
      expect(elasticsearch_client).to have_received(:index)
        .with({ index: Performance::Metrics::ELASTICSEARCH_INDEX, id: "active_users-week-#{today}", body: active_users_expected_hash.symbolize_keys })
    end
    it "indexes completion rate data into Elasticsearch" do
      completion_rate.to_elasticsearch
      expect(elasticsearch_client).to have_received(:index)
        .with({ index: Performance::Metrics::ELASTICSEARCH_INDEX, id: "completion_rate-week-#{today}", body: completion_rate_expected_hash.symbolize_keys })
    end
    it "indexes roaming users into Elasticsearch" do
      roaming_users.to_elasticsearch
      expect(elasticsearch_client).to have_received(:index)
        .with({ index: Performance::Metrics::ELASTICSEARCH_INDEX, id: "roaming_users-week-#{today}", body: roaming_users_expected_hash.symbolize_keys })
    end
    it "indexes user devices into Elasticsearch" do
      user_devices.to_elasticsearch
      expect(elasticsearch_client).to have_received(:index)
        .with({ index: Performance::Metrics::ELASTICSEARCH_INDEX, id: "user_devices-week-#{today}", body: user_devices_expected_hash.symbolize_keys })
    end
    it "indexes volumetrics data into Elasticsearch" do
      volumetrics.to_elasticsearch
      expect(elasticsearch_client).to have_received(:index)
        .with({ index: Performance::Metrics::ELASTICSEARCH_INDEX, id: "volumetrics-week-#{today}", body: volumetrics_expected_hash.symbolize_keys })
    end
  end
end
