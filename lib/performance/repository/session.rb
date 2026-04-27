# frozen_string_literal: true

class Performance::Repository::Session < Sequel::Model(:sessions)
  dataset_module do
    def request_stats(date_time:)
      sql_time = date_time.strftime("%Y-%m-%d %H:%M:%S")
      elasticsearch_time = date_time.strftime("%Y-%m-%dT%H:%M:%S")
      sql = "SELECT
               '#{elasticsearch_time}' AS time,
               siteIP,
               COUNT(CASE WHEN success='1' THEN 1 END) AS Successes,
               COUNT(CASE WHEN success='0' THEN 1 END) AS Failures
             FROM
              sessions
             WHERE
              start BETWEEN DATE_SUB('#{sql_time}', INTERVAL 1 HOUR) AND '#{sql_time}'
             GROUP BY
              siteIP"

      READ_REPLICA_DB.fetch(sql).to_a
    end

    def active_users_stats(period:, date:)
      sql = "SELECT COUNT(DISTINCT username) AS total
            FROM
              sessions
            WHERE
              start BETWEEN DATE_SUB('#{date - 1}', INTERVAL 1 #{period}) AND '#{date - 1}'
            AND
              success = 1"

      READ_REPLICA_DB.fetch(sql).first
    end

    def roaming_users_count(period:, date:)
      sql = "SELECT COUNT(*) AS total_roaming
            FROM
              (SELECT
                username,
                COUNT(DISTINCT location_id) AS roam_count
              FROM
                sessions s
              INNER JOIN
                ip_locations il ON s.siteIP = il.ip
              WHERE
                s.success = 1
              AND
                start > DATE_SUB('#{date}', INTERVAL 1 #{period})
              GROUP BY
                username
              HAVING
                roam_count > 1) AS roaming_count"

      READ_REPLICA_DB.fetch(sql).first
    end

    def cba_users_count(period:, date:)
      sql = "SELECT COUNT(DISTINCT cert_serial, cert_issuer) AS cba_count
             FROM
               sessions
             WHERE
               username IS NULL
             AND
               start > DATE_SUB('#{date}', INTERVAL 1 #{period})
             AND
               success = 1"

      READ_REPLICA_DB.fetch(sql).first
    end

    def average_unique_devices_per_user(period:, date:)
      sql = "SELECT AVG(mac_count) AS average_devices_per_user
            FROM
              (SELECT
                username,
                COUNT(DISTINCT mac) AS mac_count
              FROM
                sessions
              WHERE
                username IS NOT NULL
              AND
                start > DATE_SUB('#{date.strftime('%Y-%m-%d %H:%M:%S')}', INTERVAL 1 #{period})
              GROUP BY
                username) AS user_devices"

      READ_REPLICA_DB.fetch(sql).first
    end

    def month_to_date_active_users(period:, date:)
      sql = "SELECT COUNT(DISTINCT username) AS total
            FROM
              sessions
            WHERE
              start BETWEEN DATE_FORMAT('#{date}', '%Y-%m-01') AND '#{date}'
            AND
              success = 1"

      READ_REPLICA_DB.fetch(sql).first
    end

    def monthly_rolling_active_users(period:, date:)
      sql = "SELECT COUNT(DISTINCT username) AS total
            FROM
              sessions
            WHERE
              start BETWEEN '#{date}' - INTERVAL 31 #{period} AND '#{date}' - INTERVAL 1 #{period}
            AND
              success = 1"

      READ_REPLICA_DB.fetch(sql).first
    end
  end
end
