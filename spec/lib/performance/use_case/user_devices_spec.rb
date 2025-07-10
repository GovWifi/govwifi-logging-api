describe Performance::UseCase::UserDevices do
  let(:sessions) { DB[:sessions] }
  let(:today) { Date.today }

  before do
    sessions.truncate
  end

  context "when calculating average unique devices per user" do
    subject { described_class.new(period: "week", date: today) }

    context "with multiple users and devices" do
      before do
        sessions.insert(username: "user1", mac: "mac1", start: today - 2, success: 1)
        sessions.insert(username: "user1", mac: "mac2", start: today - 2, success: 1)
        sessions.insert(username: "user2", mac: "mac3", start: today - 2, success: 1)
      end

      it "returns the correct average" do
        result = subject.fetch_stats

        expect(result).to eq(
          devices: 1.5, # (2 + 1) / 2 users
          metric_name: "user-devices",
          period: "week",
          date: today.to_s,
        )
      end
    end

    context "with one user and one device" do
      before do
        sessions.insert(username: "user1", mac: "mac1", start: today - 2, success: 1)
      end

      it "returns 1.0 as the average" do
        result = subject.fetch_stats

        expect(result).to eq(
          devices: 1.0,
          metric_name: "user-devices",
          period: "week",
          date: today.to_s,
        )
      end
    end

    context "with no sessions in period" do
      it "returns nil" do
        result = subject.fetch_stats

        expect(result).to eq(
          devices: nil,
          metric_name: "user-devices",
          period: "week",
          date: today.to_s,
        )
      end
    end
  end
end
