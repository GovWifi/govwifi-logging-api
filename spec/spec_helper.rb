require "logger"
require "factory_bot"
require "faker"
require "rack/test"
require "rspec"
require "simplecov"
require "sequel"
require "webmock/rspec"
require "timecop"

ENV["RACK_ENV"] = "test"

require File.expand_path "../app.rb", __dir__

module RSpecMixin
  include Rack::Test::Methods
  def app
    described_class
  end
end

SimpleCov.start

RSpec.configure do |c|
  c.include RSpecMixin
  c.include FactoryBot::Syntax::Methods
  c.before(:suite) do
    FactoryBot.find_definitions
  end
end
