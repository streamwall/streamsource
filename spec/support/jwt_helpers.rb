module JwtHelpers
  def generate_jwt_token(user)
    payload = {
      user_id: user.id,
      email: user.email,
      role: user.role,
      exp: 24.hours.from_now.to_i
    }
    
    JWT.encode(payload, Rails.application.secret_key_base)
  end
  
  def auth_headers(user)
    { 'Authorization' => "Bearer #{generate_jwt_token(user)}" }
  end
  
  def expired_auth_headers(user)
    payload = {
      user_id: user.id,
      email: user.email,
      role: user.role,
      exp: 1.hour.ago.to_i
    }
    
    token = JWT.encode(payload, Rails.application.secret_key_base)
    { 'Authorization' => "Bearer #{token}" }
  end
  
  def invalid_auth_headers
    { 'Authorization' => 'Bearer invalid.token.here' }
  end
end

RSpec.configure do |config|
  config.include JwtHelpers
end