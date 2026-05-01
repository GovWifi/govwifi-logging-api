class Performance::UseCase::MonthToDateTotalActiveUsers
  def initialize(period:, date: Date.today)
    @period = period
    @date = date
  end

  def fetch_stats
    result = repository.month_to_date_total_active_users || Hash.new(0)

    {
      users: result[:total],
      run_time: result[:run_time],
      metric_name: "month-to-date-total-active-users",
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
