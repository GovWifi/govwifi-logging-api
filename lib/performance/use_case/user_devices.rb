class Performance::UseCase::UserDevices
  def initialize(period:, date: Date.today)
    @period = period
    @date = date
  end

  def fetch_stats
    result = repository.average_unique_devices_per_user(period:, date:) || Hash.new(0)

    {
      devices: result.fetch(:average_devices_per_user),
      metric_name: "user-devices",
      period:,
      date: date.to_s,
    }
  end

private

  def repository
    Performance::Repository::Session
  end

  attr_reader :period, :date
end
