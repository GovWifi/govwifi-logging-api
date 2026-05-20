# frozen_string_literal: true

describe Performance::Metrics::MetricsApiPublisher do
  let(:api_endpoint) { "https://metrics.development.wifi.service.gov.uk" }
  let(:expected_url) { "https://metrics.development.wifi.service.gov.uk/v1/record" }
  let(:api_token) { "1e5e66d8c234912aaca969731b5d390385cdd882497d5e7fcd67efc7c485a5f4" }

  before do
    ENV["METRICS_API_ENDPOINT"] = api_endpoint
    ENV["METRICS_API_BEARER_TOKEN"] = api_token
  end

  describe ".publish" do
    let(:stats) do
      {
        "metric_name" => "monthly-rolling-window-total-active-users",
        "users" => 116,
        "run_time" => "2026-05-20"
      }
    end

    let(:expected_payload) do
      {
        "name" => "monthly-rolling-window-total-active-users",
        "value" => "116",
        "datetime" => "2026-05-20T00:00:00Z"
      }
    end

    it "POSTs stats to the metrics API and returns the Faraday response" do
      stub = stub_request(:post, expected_url).to_return(status: 201, body: "created")

      response = described_class.publish(stats)

      expect(stub).to have_been_requested.once
      expect(response).to be_a(Faraday::Response)
      expect(response.status).to eq(201)
    end

    it "sends the transformed stats as JSON with auth headers" do
      stub = stub_request(:post, expected_url).with(
        body: expected_payload.to_json,
        headers: {
          "Authorization" => "Bearer #{api_token}",
          "Content-Type" => "application/json",
        },
      )

      described_class.publish(stats)

      expect(stub).to have_been_requested.once
    end

    it "handles symbol keys in stats" do
      symbol_stats = {
        metric_name: "monthly-rolling-window-total-active-users",
        users: 116,
        run_time: "2026-05-20"
      }
      stub = stub_request(:post, expected_url).with(body: expected_payload.to_json)

      described_class.publish(symbol_stats)

      expect(stub).to have_been_requested.once
    end

    it "does not append Z to datetime if it already has Z" do
      stats_with_z = {
        "metric_name" => "monthly-rolling-window-total-active-users",
        "users" => 116,
        "run_time" => "2026-05-20Z"
      }
      expected_payload_with_z = {
        "name" => "monthly-rolling-window-total-active-users",
        "value" => "116",
        "datetime" => "2026-05-20Z"
      }
      stub = stub_request(:post, expected_url).with(body: expected_payload_with_z.to_json)

      described_class.publish(stats_with_z)

      expect(stub).to have_been_requested.once
    end

    it "handles missing/nil run_time gracefully" do
      stats_without_runtime = {
        "metric_name" => "monthly-rolling-window-total-active-users",
        "users" => 116
      }
      expected_payload_without_runtime = {
        "name" => "monthly-rolling-window-total-active-users",
        "value" => "116",
        "datetime" => nil
      }
      stub = stub_request(:post, expected_url).with(body: expected_payload_without_runtime.to_json)

      described_class.publish(stats_without_runtime)

      expect(stub).to have_been_requested.once
    end

    context "when the endpoint has a trailing slash" do
      let(:api_endpoint) { "https://metrics.development.wifi.service.gov.uk/" }

      it "POSTs stats to the joined /v1/record endpoint correctly without double slashes" do
        stub = stub_request(:post, expected_url).to_return(status: 201, body: "created")

        response = described_class.publish(stats)

        expect(stub).to have_been_requested.once
        expect(response.status).to eq(201)
      end
    end

    describe "when the API request fails" do
      let(:test_logger) { Logger.new(StringIO.new) }

      before do
        described_class.logger = test_logger
      end

      after do
        described_class.logger = nil
      end

      context "when there is a connection error" do
        before do
          stub_request(:post, expected_url).to_raise(Faraday::ConnectionFailed.new("Connection refused"))
        end

        it "does not raise an error and returns nil" do
          expect(described_class.publish(stats)).to be_nil
        end

        it "logs a warning" do
          expect(test_logger).to receive(:warn).with("Metrics API request failed: Connection refused (endpoint: #{api_endpoint})")
          described_class.publish(stats)
        end
      end

      context "when there is a timeout" do
        before do
          stub_request(:post, expected_url).to_timeout
        end

        it "does not raise an error and returns nil" do
          expect(described_class.publish(stats)).to be_nil
        end

        it "logs a warning" do
          expect(test_logger).to receive(:warn).with(/Metrics API request failed/)
          described_class.publish(stats)
        end
      end
    end
  end
end
