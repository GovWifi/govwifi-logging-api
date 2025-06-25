task sync_s3_volumetrics: :load_env do
  bucket = ENV.fetch("S3_METRICS_BUCKET")

  Performance::UseCase::SyncS3ToElasticsearch.new(
    elasticsearch_gateway: Performance::Gateway::Elasticsearch.new(Performance::Metrics::ELASTICSEARCH_INDEX),
    s3_gateway: Performance::Gateway::S3.new("volumetrics", bucket),
  ).execute

  Performance::UseCase::SyncS3ToElasticsearch.new(
    elasticsearch_gateway: Performance::Gateway::Elasticsearch.new(Performance::Metrics::ELASTICSEARCH_INDEX),
    s3_gateway: Performance::Gateway::S3.new("active_users", bucket),
  ).execute

  Performance::UseCase::SyncS3ToElasticsearch.new(
    elasticsearch_gateway: Performance::Gateway::Elasticsearch.new(Performance::Metrics::ELASTICSEARCH_INDEX),
    s3_gateway: Performance::Gateway::S3.new("roaming_users", bucket),
  ).execute

  Performance::UseCase::SyncS3ToElasticsearch.new(
    elasticsearch_gateway: Performance::Gateway::Elasticsearch.new(Performance::Metrics::ELASTICSEARCH_INDEX),
    s3_gateway: Performance::Gateway::S3.new("completion_rate", bucket),
  ).execute

  Performance::UseCase::SyncS3ToElasticsearch.new(
    elasticsearch_gateway: Performance::Gateway::Elasticsearch.new(Performance::Metrics::ELASTICSEARCH_INDEX),
    s3_gateway: Performance::Gateway::S3.new("user_devices", bucket),
  ).execute
end
