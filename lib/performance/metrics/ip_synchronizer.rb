# frozen_string_literal: true

require "aws-sdk-s3"

module Performance::Metrics
  class IPSynchronizer
    def execute
      truncate_ip_locations
      save data
    end

  private

    def data
      bucket = ENV.fetch("S3_PUBLISHED_LOCATIONS_IPS_BUCKET")
      key = ENV.fetch("S3_PUBLISHED_LOCATIONS_IPS_OBJECT_KEY")

      response = Services.s3_client.get_object(bucket:, key:)
      JSON.parse(response.body.read)
    end

    def save(ip_locations)
      data = ip_locations.map(&:values)

      DB[:ip_locations].import(%i[ip location_id], data)
    end

    def truncate_ip_locations
      DB[:ip_locations].truncate
    end
  end
end
