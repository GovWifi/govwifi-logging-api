task :sync_s3_to_data_bucket, %i[source_bucket dest_bucket] => :load_env do |_, args|
  puts "Copy from #{args[:source_bucket]} to #{args[:dest_bucket]}"
  %w[volumetrics active_users roaming_users completion_rate user_devices].each do |dataset|
    Performance::UseCase::SyncS3ToDataBucket.new(
      dest_bucket: args[:dest_bucket], dest_key: dataset,
      s3_gateway: Performance::Gateway::S3.new(dataset, args[:source_bucket])
    ).execute
  end
end
