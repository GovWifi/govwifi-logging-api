# frozen_string_literal: true

require "date"

desc "Update last login"
task update_yesterdays_last_login: :load_env do
  date = Date.today.prev_day
  logger = Logger.new($stdout)
  logger.info("Populating the last_login field in the user database from the session database at #{date}")

  number_updated = Gdpr::UseCase::PopulateUserLastLogin.new(
    session_gateway: Gdpr::Gateway::Session.new,
    last_login_gateway: Gdpr::Gateway::SetLastLogin.new,
  ).execute(date: Date.today.prev_day)

  logger.info("Updated the last_login field of #{number_updated} records to #{date}")
end
