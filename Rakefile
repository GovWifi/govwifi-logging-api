desc "require all classes"
task :load_env do
  # Set a long connection timeout here, since some of the queries run
  # through the rake tasks may take several hours to complete
  ::DB_CONNECTION_TIMEOUT = 12 * 60 * 60

  require_relative "./lib/loader"
end

require_relative "./tasks/migrate"
require_relative "./tasks/publish_statistics"
require_relative "./tasks/send_request_statistics"
require_relative "./tasks/session_deletion"
require_relative "./tasks/smoke_tests_clean"
require_relative "./tasks/sync_s3_volumetrics"
require_relative "./tasks/sync_s3_to_data_bucket"
require_relative "./tasks/update_last_login"
require_relative "./tasks/recover_active_users"
