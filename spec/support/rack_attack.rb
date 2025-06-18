# Disable Rack::Attack by default in tests
Rack::Attack.enabled = false

RSpec.configure do |config|
  # Disable Rack::Attack for all tests by default
  config.before(:suite) do
    Rack::Attack.enabled = false
  end
end