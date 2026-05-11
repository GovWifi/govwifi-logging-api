class Performance::UseCase::MonthlyRollingWindowTotalRoamingUsers
  def initialize(period:, date: Date.today)
    @period = period
    @date = date
  end

  def fetch_stats
    result = repository.monthly_rolling_window_total_roaming_users || Hash.new(0)

    {
      users: result[:rolling_total_roaming],
      run_time: result[:run_time],
      metric_name: "monthly-rolling-window-total-roaming-users",
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
