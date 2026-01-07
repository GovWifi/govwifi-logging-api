source "http://rubygems.org"
ruby File.read(".ruby-version").chomp

gem "aws-sdk-s3"
gem "faraday"
gem "opensearch-ruby"
gem "puma"
gem "rake"
gem "require_all"
gem "rexml"
gem "sensible_logging"
gem "sentry-raven"
gem "sequel"
gem "sinatra"
gem "sinatra-contrib"

group :test do
  gem "factory_bot"
  gem "faker"
  gem "mysql2", "~> 0.5.7"
  gem "rack-test"
  gem "rspec"
  gem "rubocop", "~> 1.82.1"
  # Pull directly from GitHub main to get the latest gemspec changes, till it gets released.
  gem "rubocop-govuk", github: "alphagov/rubocop-govuk", branch: "main", require: false
  gem "simplecov"
  gem "timecop"
  gem "webmock"
end
