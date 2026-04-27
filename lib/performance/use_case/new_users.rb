# frozen_string_literal: true

class Performance::UseCase::NewUsers
  def initialize(period:, date: Date.today)
    last_month = date << 1
    @period = period
    @start_date = Date.new(last_month.year, last_month.month, 1)
    @end_date = (@start_date >> 1) - 3
  end

  def fetch_stats
    return nil unless @period == "month"

    {
      new_active_users: repository.new_active_users(@start_date, @end_date),
      new_inactive_users: repository.new_inactive_users(@start_date, @end_date),
      days: @end_date - @start_date,
      metric_name: "inactive-users",
      period: "monthly",
      date: @start_date.to_s,
    }
  end

private

  def repository
    Performance::Repository::SignUp
  end
end
