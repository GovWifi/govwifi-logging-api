class Performance::UseCase::MonthToDateTotalActiveUsers
  def fetch_stats
    result = repository.month_to_date_total_active_users || Hash.new(0)

    {
      users: result[:total],
      run_time: result[:run_time],
      metric_name: "month-to-date-total-active-users",
      period: "daily",
      date: Date.today.to_s,
    }
  end

private

  def repository
    Performance::Repository::Session
  end
end
