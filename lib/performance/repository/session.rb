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
      DB.fetch(sql).to_a
    end

    def active_users_stats(period:, date:)
      DB.fetch("
        SELECT
          count(distinct(username)) as total
        FROM sessions WHERE start BETWEEN date_sub('#{date - 1}', INTERVAL 1 #{period}) AND '#{date - 1}'
          AND sessions.success = 1").first
    end

    def roaming_users_count(period:, date:)
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
                start BETWEEN date_sub('#{date}', INTERVAL 1 #{period}) AND '#{date}'
              GROUP BY
                username
              HAVING
                roam_count > 1)
             as roaming_count"

      DB.fetch(sql).first
    end
  end
end
