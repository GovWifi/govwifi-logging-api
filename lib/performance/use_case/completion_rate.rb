# frozen_string_literal: true

class Performance::UseCase::CompletionRate
  def initialize(date: Date.today, period: "week")
    @date = date
    @period = period
  end

  def fetch_stats
    {
      period: @period,
      date: date.to_s,
      metric_name: "completion-rate",
      cumulative_all_registered: cumulative_all_registered.count,
      cumulative_sms_registered: cumulative_sms_registered.count,
      cumulative_email_registered: cumulative_email_registered.count,
      cumulative_sponsor_registered: cumulative_sponsor_registered.count,
      cumulative_all_logged_in: cumulative_all_logged_in.count,
      cumulative_sms_logged_in: cumulative_sms_logged_in.count,
      cumulative_email_logged_in: cumulative_email_logged_in.count,
      cumulative_sponsor_logged_in: cumulative_sponsor_logged_in.count,
      all_registered: all_registered.count,
      sms_registered: sms_registered.count,
      email_registered: email_registered.count,
      sponsor_registered: sponsor_registered.count,
      all_logged_in: all_logged_in.count,
      sms_logged_in: sms_logged_in.count,
      email_logged_in: email_logged_in.count,
      sponsor_logged_in: sponsor_logged_in.count,
    }
  end

private

  attr_reader :date

  def repository
    Performance::Repository::SignUp
  end

  def cumulative_all_registered
    repository.all(date)
  end

  def cumulative_sms_registered
    cumulative_all_registered.self_sign.with_sms
  end

  def cumulative_email_registered
    cumulative_all_registered.self_sign.with_email
  end

  def cumulative_sponsor_registered
    cumulative_all_registered.sponsored
  end

  def cumulative_all_logged_in
    cumulative_all_registered.with_successful_login
  end

  def cumulative_sms_logged_in
    cumulative_sms_registered.with_successful_login
  end

  def cumulative_email_logged_in
    cumulative_email_registered.with_successful_login
  end

  def cumulative_sponsor_logged_in
    cumulative_sponsor_registered.with_successful_login
  end

  def all_registered
    repository.send("#{@period}_before", date)
  end

  def sms_registered
    all_registered.self_sign.with_sms
  end

  def email_registered
    all_registered.self_sign.with_email
  end

  def sponsor_registered
    all_registered.sponsored
  end

  def all_logged_in
    all_registered.with_successful_login
  end

  def sms_logged_in
    sms_registered.with_successful_login
  end

  def email_logged_in
    email_registered.with_successful_login
  end

  def sponsor_logged_in
    sponsor_registered.with_successful_login
  end
end
