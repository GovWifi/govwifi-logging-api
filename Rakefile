# frozen_string_literal: true

desc "Setup the database environment and load all modules and classes"
task :load_env do
  # Set a long connection timeout here, since some of the queries run
  # through the rake tasks may take several hours to complete
  ::DB_CONNECTION_TIMEOUT = 12 * 60 * 60

  require "./lib/loader"
end

require "./tasks/migrate"
require "./tasks/publish_statistics"
require "./tasks/send_request_statistics"
require "./tasks/session_deletion"
require "./tasks/smoke_tests_clean"
require "./tasks/sync_s3_volumetrics"
require "./tasks/sync_s3_to_data_bucket"
require "./tasks/update_last_login"
