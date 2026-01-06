# frozen_string_literal: true

require "sequel"
require "sensible_logging"
require "sinatra/base"
require "sinatra/json"

# Set a short connection timeout, since queries here need to execute
# before the request times out
DB_CONNECTION_TIMEOUT = 10

require "./lib/loader"

class App < Sinatra::Base
  use Raven::Rack if defined? Raven
  register Sinatra::SensibleLogging

  sensible_logging(
    logger: Logger.new($stdout),
    log_tags: [lambda { |req|
      req.body&.rewind
      [
        req.body&.read,
      ].tap { req.body&.rewind }
    }],
  )

  configure do
    enable :json
    set :log_level, Logger::DEBUG
  end

  configure :production, :staging do
    set :dump_errors, false
  end

  configure :production do
    set :log_level, Logger::INFO
  end

  get "/" do
    # k8s health check usually need the root to respond with 200 ok. Its also
    # useful to have something basic on the site root instead of a 404.
    { "status": "ok" }.to_json
  end

  get "/healthcheck" do
    "Healthy"
  end

  post "/logging/post-auth" do
    request.body.rewind
    Logging::PostAuth.new.execute(params: JSON.parse(request.body.read))

    status 204
  end
end
