# frozen_string_literal: true

describe Performance::UseCase::MonthlyRollingWindowPeapUniqueUsers do
  let(:sessions) { DB[:sessions] }
  let(:result) { subject.fetch_stats }
  let(:today) { Date.today }

  subject { described_class.new(period: "day", date: today) }

  before do
    sessions.truncate
  end

  context "with PEAP users connecting once in the 30-day window" do
    before do
      sessions.insert(
        siteIP: "10.0.0.1",
        username: "USER01",
        start: today - 10,
        success: 1,
      )

      sessions.insert(
        siteIP: "10.0.0.2",
        username: "USER02",
        start: today - 5,
        success: 1,
      )
    end

    it "counts both distinct PEAP users" do
      expect(result).to eq(
        count: 2,
        run_time: today.to_s,
        metric_name: "service-report-peap-unique-users-rolling-count",
        period: "day",
        date: today.to_s,
      )
    end
  end

  context "with multiple connections by the same PEAP user" do
    before do
      sessions.insert(
        siteIP: "10.0.0.1",
        username: "USER01",
        start: today - 10,
        success: 1,
      )

      sessions.insert(
        siteIP: "10.0.0.2",
        username: "USER01",
        start: today - 2,
        success: 1,
      )
    end

    it "counts each PEAP user only once" do
      expect(result[:count]).to eq(1)
    end
  end

  context "with TLS sessions where username is null" do
    before do
      sessions.insert(
        siteIP: "10.0.0.1",
        username: nil,
        cert_serial: "SERIAL123",
        cert_issuer: "GovWifi CA",
        start: today - 5,
        success: 1,
      )
    end

    it "ignores sessions with a null username" do
      expect(result[:count]).to eq(0)
    end
  end

  context "with failed PEAP authentication sessions" do
    before do
      sessions.insert(
        siteIP: "10.0.0.1",
        username: "USER01",
        start: today - 5,
        success: 0,
      )
    end

    it "ignores unsuccessful sessions" do
      expect(result[:count]).to eq(0)
    end
  end

  context "with PEAP connections outside the rolling window" do
    before do
      sessions.insert(
        siteIP: "10.0.0.1",
        username: "USER01",
        start: today - 35,
        success: 1,
      )
    end

    it "ignores sessions older than 31 days" do
      expect(result[:count]).to eq(0)
    end
  end

  context "with an empty sessions table" do
    it "returns 0" do
      expect(result).to eq(
        count: 0,
        run_time: today.to_s,
        metric_name: "service-report-peap-unique-users-rolling-count",
        period: "day",
        date: today.to_s,
      )
    end
  end
end
