class Performance::Gateway::S3
  include Enumerable

  def initialize(prefix, bucket)
    @prefix = "#{prefix}/"
    @bucket = bucket
  end

  def each(&block)
    keys.each do |key|
      json = Services.s3_client.get_object(bucket: @bucket, key:)
      body = json.body.read

      # Skip if the object body is empty or nil
      next if body.to_s.strip.empty?

      begin
        parsed = JSON.parse(body)
        block.call(key[@prefix.length..], parsed)
      rescue JSON::ParserError => e
        warn "Skipping invalid JSON object in #{@bucket}/#{key}: #{e.message}"
        next
      end
    end
  end

private

  def keys
    list_objects.map(&:key)
  end

  def list_objects(continuation_token = nil)
    response = Services.s3_client.list_objects_v2({ bucket: @bucket, prefix: @prefix, continuation_token: })
    objects = response.data.contents

    if response.data.is_truncated
      objects += list_objects(response.data.next_continuation_token)
    end

    objects
  rescue Aws::S3::Errors::AccessDenied => e
    warn "Failed to connect to S3 with bucket: #{@bucket.inspect}, prefix: #{@prefix.inspect}, continuation_token: #{continuation_token.inspect}"
    raise e
  end
end
