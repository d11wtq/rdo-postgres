require "rdo"
require "rdo/postgres"

ENV["CONNECTION"] ||= "postgresql://test:test@localhost/testdb?encoding=utf-8"

RSpec.configure do |config|
  def connection_uri
    ENV["CONNECTION"]
  end
end
