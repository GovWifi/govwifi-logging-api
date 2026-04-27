# frozen_string_literal: true

class Performance::UseCase::MonthlyRollingActiveUsers
  def initialize(period:, date: Date.today)
    @period = period
    @date = date
  end

  def fetch_stats
    result = repository.monthly_rolling_active_users(period:, date:) || Hash.new(0)

    {
      users: result[:total],
      metric_name: "monthly-rolling-active-users",
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
