# frozen_string_literal: true

require "logger"

class Gdpr::Gateway::Session
  SESSION_BATCH_SIZE = 500
  def delete_sessions
    logger = Logger.new($stdout)

    logger.info("Starting daily session deletion")

    total = 0
    loop do
      deleted_rows = DB[:sessions].with_sql_delete("DELETE FROM sessions WHERE start < DATE_SUB(DATE(NOW()), INTERVAL 32 DAY) LIMIT #{SESSION_BATCH_SIZE}")
      total += deleted_rows

      if deleted_rows.zero?
        break
      end
    end

    logger.info("Finished daily session deletion, #{total} rows affected")
  end

  def active_users(date:)
    Session.select(:username).distinct
      .where(Sequel.lit("start >= ? and start < ?", date, date.next_day))
      .map(:username)
  end
end
