# Rack::Attack configuration for rate limiting
class Rack::Attack
  # Key prefix for Redis
  redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'))
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(redis: redis)
  
  # Allow all requests from localhost
  safelist('allow-localhost') do |req|
    req.ip == '127.0.0.1' || req.ip == '::1'
  end
  
  # Throttle all requests by IP (100 requests per minute)
  throttle('req/ip', limit: 100, period: 1.minute) do |req|
    req.ip
  end
  
  # Throttle login attempts by IP (5 requests per 20 minutes)
  throttle('logins/ip', limit: 5, period: 20.minutes) do |req|
    req.ip if req.path == '/api/v1/users/login' && req.post?
  end
  
  # Throttle login attempts by email (5 requests per 20 minutes)
  throttle('logins/email', limit: 5, period: 20.minutes) do |req|
    if req.path == '/api/v1/users/login' && req.post?
      req.params['email'].to_s.downcase.presence
    end
  end
  
  # Throttle signup attempts by IP (3 requests per hour)
  throttle('signups/ip', limit: 3, period: 1.hour) do |req|
    req.ip if req.path == '/api/v1/users/signup' && req.post?
  end
  
  # Exponential backoff for repeated violations
  (2..6).each do |level|
    throttle("req/ip/#{level}", limit: (50 * level), period: (8**level).seconds) do |req|
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
    
    [429, headers, [{ error: 'Too many requests. Please try again later.' }.to_json]]
  end
end