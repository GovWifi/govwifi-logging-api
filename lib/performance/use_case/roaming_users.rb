# frozen_string_literal: true

class Performance::UseCase::RoamingUsers
  def initialize(period:, date: Date.today)
    @period = period.to_s
    @date = date
  end

  def fetch_stats
    {
      active: active_users_count,
      roaming: roaming_users_count,
      cba: cba_users_count,
      metric_name: "roaming-users",
      period:,
      date: date.to_s,
    }
  end

private

  def repository
    Performance::Repository::Session
  end

  def active_users_count
    repository.active_users_stats(period:, date:).fetch(:total)
  end

  def roaming_users_count
    repository.roaming_users_count(period:, date:).fetch(:total_roaming)
  end

  def cba_users_count
    repository.cba_users_count(period:, date:).fetch(:cba_count)
  end

  attr_reader :period, :date
end
