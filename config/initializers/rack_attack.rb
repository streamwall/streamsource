# Rack::Attack configuration for rate limiting
class Rack::Attack
  # Key prefix for Redis
  if ENV['REDIS_URL'].present? || Rails.env.production?
    require 'redis'
    redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'))
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(redis: redis)
  else
    # Use memory store in development/test without Redis
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end
  
  # Allow all requests from localhost
  safelist('allow-localhost') do |req|
    req.ip == '127.0.0.1' || req.ip == '::1'
  end
  
  # Throttle all requests by IP
  throttle('req/ip', limit: ApplicationConstants::RateLimit::REQUESTS_PER_MINUTE, period: 1.minute) do |req|
    req.ip
  end
  
  # Throttle login attempts by IP
  throttle('logins/ip', limit: ApplicationConstants::RateLimit::LOGIN_ATTEMPTS_PER_PERIOD, period: ApplicationConstants::RateLimit::LOGIN_PERIOD) do |req|
    req.ip if req.path == '/api/v1/users/login' && req.post?
  end
  
  # Throttle login attempts by email
  throttle('logins/email', limit: ApplicationConstants::RateLimit::LOGIN_ATTEMPTS_PER_PERIOD, period: ApplicationConstants::RateLimit::LOGIN_PERIOD) do |req|
    if req.path == '/api/v1/users/login' && req.post?
      req.params['email'].to_s.downcase.presence
    end
  end
  
  # Throttle signup attempts by IP
  throttle('signups/ip', limit: ApplicationConstants::RateLimit::SIGNUP_ATTEMPTS_PER_PERIOD, period: ApplicationConstants::RateLimit::SIGNUP_PERIOD) do |req|
    req.ip if req.path == '/api/v1/users/signup' && req.post?
  end
  
  # Exponential backoff for repeated violations
  ApplicationConstants::RateLimit::BACKOFF_LEVELS.each do |level|
    throttle("req/ip/#{level}", limit: (50 * level), period: (ApplicationConstants::RateLimit::BACKOFF_BASE**level).seconds) do |req|
      req.ip if req.env['rack.attack.matched'] && req.env['rack.attack.match_type'] == :throttle
    end
  end
  
  # Custom response for throttled requests
  self.throttled_responder = lambda do |request|
    match_data = request.env['rack.attack.match_data']
    now = match_data[:epoch_time]
    
    headers = {
      'Content-Type' => 'application/json',
      'X-RateLimit-Limit' => match_data[:limit].to_s,
      'X-RateLimit-Remaining' => '0',
      'X-RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s
    }
    
    [429, headers, [{ error: ApplicationConstants::Messages::RATE_LIMITED }.to_json]]
  end
end