module JwtHelpers
  # Generate a JWT token with custom options
  def generate_jwt_token(user, options = {})
    payload = build_jwt_payload(user, options)
    JWT.encode(payload, jwt_secret, ApplicationConstants::JWT::ALGORITHM)
  end

  # Build JWT payload with default and custom attributes
  def build_jwt_payload(user, options = {})
    default_payload = {
      user_id: user.id,
      email: user.email,
      role: user.role,
      exp: (options[:exp] || ApplicationConstants::JWT::EXPIRATION_TIME.from_now).to_i,
    }

    # Allow custom payload attributes
    default_payload.merge(options.except(:exp))
  end

  # Generate authorization headers with valid token
  def auth_headers(user, options = {})
    { "Authorization" => "Bearer #{generate_jwt_token(user, options)}" }
  end

  # Generate headers with expired token
  def expired_auth_headers(user, expire_time = 1.hour.ago)
    auth_headers(user, exp: expire_time)
  end

  # Generate headers with invalid token
  def invalid_auth_headers
    { "Authorization" => "Bearer invalid.token.here" }
  end

  # Generate headers with malformed authorization
  def malformed_auth_headers
    { "Authorization" => "NotBearer token" }
  end

  # Generate headers without authorization
  def no_auth_headers
    {}
  end

  # Decode a JWT token (useful for testing)
  def decode_jwt_token(token)
    JWT.decode(token, jwt_secret, true, algorithm: ApplicationConstants::JWT::ALGORITHM)
  rescue JWT::DecodeError => e
    { error: e.message }
  end

  private

  def jwt_secret
    Rails.application.secret_key_base
  end
end

RSpec.configure do |config|
  config.include JwtHelpers
end
