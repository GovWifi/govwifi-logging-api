# frozen_string_literal: true

module Performance::Metrics
  class S3Publisher
    def self.publish(key, stats)
      bucket = ENV.fetch("S3_METRICS_BUCKET")

      Services.s3_client.put_object(
        bucket:,
        key:,
        body: stats.to_json.to_s,
      )
    end
  end
end
