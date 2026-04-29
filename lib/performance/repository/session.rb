class Performance::Repository::Session < Sequel::Model(:sessions)
  dataset_module do
    def request_stats(date_time:)
      sql_time = date_time.strftime("%Y-%m-%d %H:%M:%S")
      elasticsearch_time = date_time.strftime("%Y-%m-%dT%H:%M:%S")
      sql = "SELECT
               '#{elasticsearch_time}' AS time,
               siteIP,
               COUNT(CASE WHEN success='1' THEN 1 end) AS Successes,
               COUNT(CASE WHEN success='0' THEN 1 end) AS Failures
             FROM sessions WHERE start BETWEEN date_sub('#{sql_time}', INTERVAL 1 HOUR) AND '#{sql_time}'
             GROUP BY siteIP"
      READ_REPLICA_DB.fetch(sql).to_a
    end

    def active_users_stats(period:, date:)
      READ_REPLICA_DB.fetch("
        SELECT
          count(distinct(username)) as total
        FROM sessions WHERE start BETWEEN date_sub('#{date - 1}', INTERVAL 1 #{period}) AND '#{date - 1}'
          AND sessions.success = 1").first
    end

    def roaming_users_count(period:)
      sql = "SELECT COUNT(*) as total_roaming FROM (
              SELECT
                username, count(distinct(location_id)) as roam_count
              FROM
                sessions s
              INNER JOIN
                ip_locations il on s.siteIP = il.ip
              WHERE
                s.success = 1
              AND
                start > date_sub(CURDATE(), INTERVAL 1 #{period})
              GROUP BY
                username
              HAVING
                roam_count > 1)
             as roaming_count"

      READ_REPLICA_DB.fetch(sql).first
    end

    def cba_users_count(period:)
      sql = "SELECT COUNT(DISTINCT cert_serial, cert_issuer) AS cba_count
             FROM
               sessions
             WHERE
               username IS NULL
             AND
               start > date_sub(CURDATE(), INTERVAL 1 #{period})
             AND
               success = 1"

      READ_REPLICA_DB.fetch(sql).first
    end

    def average_unique_devices_per_user(period:, date:)
      sql = "SELECT AVG(mac_count) AS average_devices_per_user
            FROM (
              SELECT username, COUNT(DISTINCT mac) AS mac_count
              FROM sessions
              WHERE username IS NOT NULL
                AND start > DATE_SUB('#{date.strftime('%Y-%m-%d %H:%M:%S')}', INTERVAL 1 #{period})
              GROUP BY username
            ) AS user_devices"
      READ_REPLICA_DB.fetch(sql).first
    end

    def month_to_date_total_roaming_users
      sql = "SELECT
              DATE_FORMAT(CURDATE(), '%Y-%m-%d') AS MTD,
              COUNT(*) AS active_count
            FROM
              (SELECT
                username,
                COUNT(DISTINCT location_id) AS roaming_count
              FROM
                sessions s
              INNER JOIN ip_locations il ON s.siteIP = il.ip
              WHERE
                s.success = 1
              AND
                start >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
              GROUP BY
                username
              HAVING
                roaming_count > 1)
            AS active_count"

      READ_REPLICA_DB.fetch(sql).first
    end

    def monthly_rolling_window_total_roaming_users
      sql = "SELECT
              CURDATE() AS run_date,
              COUNT(*) AS rolling_total_roaming
            FROM
              (SELECT
                username,
                COUNT(DISTINCT location_id) AS roaming_count
              FROM
                sessions s
              INNER JOIN ip_locations il ON s.siteIP = il.ip
              WHERE
                s.success = 1
              AND
                start >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
              GROUP BY
                username
              HAVING
                roaming_count > 1)
            AS rolling_total_roaming"

      READ_REPLICA_DB.fetch(sql).first
    end

    def month_to_date_total_active_users
      sql = "SELECT
              DATE_FORMAT(CURDATE(), '%Y-%m-%d') AS run_time,
              COUNT(DISTINCT username) AS total
            FROM
              sessions
            WHERE
              start BETWEEN DATE_FORMAT('2026-02-20', '%Y-%m-01') AND CURRENT_DATE
            AND
              success = 1"

      READ_REPLICA_DB.fetch(sql).first
    end

    def monthly_rolling_window_total_active_users
      sql = "SELECT
              DATE_FORMAT(CURDATE(), '%Y-%m-%d') AS run_time,
              COUNT(DISTINCT username) AS total
            FROM
              sessions
            WHERE
              start BETWEEN CURRENT_DATE - INTERVAL 31 DAY AND CURRENT_DATE - INTERVAL 1 DAY
            AND
              success = 1"

      READ_REPLICA_DB.fetch(sql).first
    end
  end
end
