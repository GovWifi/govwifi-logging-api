# frozen_string_literal: true

require "opensearch"

class Services
  def self.s3_client
    @s3_client ||= Aws::S3::Client.new(region: "eu-west-2")
  end

  def self.elasticsearch_client
    @elasticsearch_client ||= OpenSearch::Client.new host: ENV["VOLUMETRICS_ENDPOINT"]
  end
end
