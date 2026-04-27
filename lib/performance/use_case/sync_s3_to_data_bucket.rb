# frozen_string_literal: true

require "logger"

class Performance::UseCase::SyncS3ToDataBucket
  def initialize(s3_gateway:, dest_bucket:, dest_key:, logger: Logger.new($stdout))
    @s3_gateway = s3_gateway
    @dest_bucket = dest_bucket
    @dest_key = dest_key
    @logger = logger
  end

  def execute
    data_array = @s3_gateway.inject([]) do |result, (_, data)|
      result << data
    end

    Services.s3_client.put_object(body: data_array.to_json, bucket: @dest_bucket, key: @dest_key)
    @logger.info "Writing #{data_array.count} records"
  end
end
