# frozen_string_literal: true

describe Performance::Metrics::ApiPublisher do
  let(:api_endpoint) { "https://metrics.development.wifi.service.gov.uk/v1/record" }
  let(:api_token) { "1e5e66d8c234912aaca969731b5d390385cdd882497d5e7fcd67efc7c485a5f4" }

  before do
    ENV["METRICS_API_ENDPOINT"] = api_endpoint
    ENV["METRICS_API_BEARER_TOKEN"] = api_token
  end

  describe ".publish" do
    let(:stats) { { "metric_name" => "monthly-rolling-window-total-active-users", "users" => 0 } }

    it "POSTs stats to the metrics API" do
      stub = stub_request(:post, api_endpoint)

      described_class.publish(stats)

      expect(stub).to have_been_requested.once
    end

    it "sends the stats as JSON with auth headers" do
      stub = stub_request(:post, api_endpoint).with(
        body: stats.to_json,
        headers: {
          "Authorization" => "Bearer #{api_token}",
          "Content-Type" => "application/json",
        },
      )

      described_class.publish(stats)

      expect(stub).to have_been_requested.once
    end
  end
end
