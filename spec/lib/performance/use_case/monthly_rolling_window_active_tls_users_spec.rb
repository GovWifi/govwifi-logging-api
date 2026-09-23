# frozen_string_literal: true

describe Performance::UseCase::MonthlyRollingWindowActiveTlsUsers do
  let(:sessions) { DB[:sessions] }
  let(:result) { subject.fetch_stats }
  let(:today) { Date.today }

  subject { described_class.new(period: "day", date: today) }

  before do
    sessions.truncate
  end

  context "with TLS users connecting once in the 30-day window" do
    before do
      sessions.insert(
        siteIP: "10.0.0.1",
        username: nil,
        cert_serial: "SERIAL123",
        cert_issuer: "GovWifi CA",
        start: today - 10,
        success: 1,
      )

      sessions.insert(
        siteIP: "10.0.0.2",
        username: nil,
        cert_serial: "SERIAL456",
        cert_issuer: "GovWifi CA",
        start: today - 5,
        success: 1,
      )
    end

    it "counts both distinct TLS users" do
      expect(result).to eq(
        count: 2,
        run_time: today.to_s,
        metric_name: "service-report-active-tls-user-rolling-count",
        period: "day",
        date: today.to_s,
      )
    end
  end

  context "with same cert_serial from different cert_issuers" do
    before do
      sessions.insert(
        siteIP: "10.0.0.1",
        username: nil,
        cert_serial: "SERIAL123",
        cert_issuer: "GovWifi CA 1",
        start: today - 10,
        success: 1,
      )

      sessions.insert(
        siteIP: "10.0.0.2",
        username: nil,
        cert_serial: "SERIAL123",
        cert_issuer: "GovWifi CA 2",
        start: today - 5,
        success: 1,
      )
    end

    it "treats them as distinct TLS users" do
      expect(result[:count]).to eq(2)
    end
  end

  context "with multiple connections by the same TLS user" do
    before do
      sessions.insert(
        siteIP: "10.0.0.1",
        username: nil,
        cert_serial: "SERIAL123",
        cert_issuer: "GovWifi CA",
        start: today - 10,
        success: 1,
      )

      sessions.insert(
        siteIP: "10.0.0.2",
        username: nil,
        cert_serial: "SERIAL123",
        cert_issuer: "GovWifi CA",
        start: today - 2,
        success: 1,
      )
    end

    it "counts each TLS user only once" do
      expect(result[:count]).to eq(1)
    end
  end

  context "with non-TLS sessions where username is present" do
    before do
      sessions.insert(
        siteIP: "10.0.0.1",
        username: "user01",
        cert_serial: "SERIAL123",
        cert_issuer: "GovWifi CA",
        start: today - 5,
        success: 1,
      )
    end

    it "ignores sessions with a non-null username" do
      expect(result[:count]).to eq(0)
    end
  end

  context "with failed TLS authentication sessions" do
    before do
      sessions.insert(
        siteIP: "10.0.0.1",
        username: nil,
        cert_serial: "SERIAL123",
        cert_issuer: "GovWifi CA",
        start: today - 5,
        success: 0,
      )
    end

    it "ignores unsuccessful sessions" do
      expect(result[:count]).to eq(0)
    end
  end

  context "with TLS connections outside the rolling window" do
    before do
      sessions.insert(
        siteIP: "10.0.0.1",
        username: nil,
        cert_serial: "SERIAL123",
        cert_issuer: "GovWifi CA",
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
        metric_name: "service-report-active-tls-user-rolling-count",
        period: "day",
        date: today.to_s,
      )
    end
  end
end
