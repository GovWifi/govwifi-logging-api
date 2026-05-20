# frozen_string_literal: true

require "sequel"
require "semantic_logger"
require "sinatra/base"
require "sinatra/json"

# Set a short connection timeout, since queries here need to execute
# before the request times out
DB_CONNECTION_TIMEOUT = 10

require "./lib/loader"

class RequestBodyLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    env["rack.input"]&.rewind
    body = env["rack.input"]&.read
    env["rack.input"]&.rewind
    SemanticLogger.tagged(body) do
      @app.call(env)
    end
  end
end

class RequestLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    status, headers, body = @app.call(env)
    duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000
    SemanticLogger["Rack"].info do
      { method: env["REQUEST_METHOD"],
        path: env["PATH_INFO"],
        status:,
        duration: duration.round(2) }
    end
    [status, headers, body]
  end
end

class App < Sinatra::Base
  use Raven::Rack if defined? Raven
  use RequestBodyLogger
  use RequestLogger

  configure do
    enable :json
    SemanticLogger.default_level = :debug
    SemanticLogger.add_appender(io: $stdout)
  end

  configure :production, :staging do
    set :dump_errors, false
  end

  configure :production do
    SemanticLogger.default_level = :info
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
