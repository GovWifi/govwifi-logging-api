class Performance::UseCase::MonthToDateTotalRoamingUsers
  def initialize(period:, date: Date.today)
    @period = period
    @date = date
  end

  def fetch_stats
    result = repository.month_to_date_total_roaming_users || Hash.new(0)

    {
      users: result[:active_count],
      run_time: result[:run_time],
      metric_name: "month-to-date-total-roaming-users",
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
