class Performance::UseCase::MonthToDateTotalRoamingUsers
  def fetch_stats
    result = repository.month_to_date_total_roaming_users || Hash.new(0)

    {
      users: result[:active_count],
      run_time: result[:MTD],
      metric_name: "month-to-date-total-roaming-users",
      period: "daily",
      date: Date.today.to_s,
    }
  end

private

  def repository
    Performance::Repository::Session
  end
end
