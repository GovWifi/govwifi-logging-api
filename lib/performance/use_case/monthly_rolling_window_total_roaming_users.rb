class Performance::UseCase::RollingMonthlyWindowTotalRoamingUsers
  def fetch_stats
    result = repository.monthly_rolling_window_total_roaming_users || Hash.new(0)

    {
      users: result[:rolling_total_roaming],
      run_date: result[:run_date],
      metric_name: "monthly-rolling-window-total-roaming-users",
      period: "daily",
      date: Date.today.to_s,
    }
  end

private

  def repository
    Performance::Repository::Session
  end
end
