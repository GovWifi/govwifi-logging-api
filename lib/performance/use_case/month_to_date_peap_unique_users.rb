# frozen_string_literal: true

class Performance::UseCase::MonthToDatePeapUniqueUsers
  def initialize(period: "day", date: Date.today)
    @period = period
    @date = date
  end

  def fetch_stats
    result = repository.month_to_date_peap_unique_users(date:) || Hash.new(0)

    {
      count: result[:total] || 0,
      run_time: result[:run_time],
      metric_name: "service-report-peap-unique-users-mtd-count",
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
