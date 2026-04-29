class Performance::UseCase::RollingMonthlyWindowTotalActiveUsers
  def fetch_stats
    result = repository.monthly_rolling_window_total_active_users || Hash.new(0)

    {
      users: result[:total],
      run_time: result[:run_time],
      metric_name: "monthly-rolling-window-total-active-users",
      period: "daily",
      date: Date.today.to_s,
    }
  end

private

  def repository
    Performance::Repository::Session
  end
end
