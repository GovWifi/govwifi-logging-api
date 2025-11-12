require "base64"
require "sequel"
require "require_all"
require "net/http"
require "json"


DB = Sequel.connect(
  adapter: "mysql2",
  host: ENV.fetch("DB_HOSTNAME"),
  port: ENV.fetch("DB_PORT", 3306),
  database: ENV.fetch("DB_NAME"),
  user: ENV.fetch("DB_USER"),
  password: ENV.fetch("DB_PASS"),
  read_timeout: DB_CONNECTION_TIMEOUT,
  max_connections: 32,
)

USER_DB = Sequel.connect(
  adapter: "mysql2",
  host: ENV.fetch("USER_DB_HOSTNAME"),
  port: ENV.fetch("USER_DB_PORT", 3306),
  database: ENV.fetch("USER_DB_NAME"),
  user: ENV.fetch("USER_DB_USER"),
  password: ENV.fetch("USER_DB_PASS"),
  max_connections: 32,
)

if %w[production staging].include?(ENV["RACK_ENV"])
  require "raven"

  Raven.configure do |config|
    config.dsn = ENV["SENTRY_DSN"]
  end
end

module Common
end

module Gdpr
  module Gateway; end

  module UseCase; end
end

module Performance
  module Gateway; end

  module Metrics; end

  module Repository; end

  module UseCase; end
end

module Smoketests
end

require_all "lib/performance/use_case"
require_all "lib"
