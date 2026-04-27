# frozen_string_literal: true

class Performance::UseCase::MonthToDateActiveUsers
  def initialize(period:, date: Date.today)
    @period = period
    @date = date
  end

  def fetch_stats
    result = repository.month_to_date_active_users(period:, date:) || Hash.new(0)

    {
      users: result[:total],
      metric_name: "month-to-date-active-users",
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
