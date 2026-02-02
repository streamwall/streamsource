class JsonWebToken
  class << self
    def encode(payload, expiration = ApplicationConstants::JWT::EXPIRATION_TIME.from_now)
      payload = payload.dup
      payload[:exp] = expiration.to_i
      JWT.encode(payload, Rails.application.secret_key_base, ApplicationConstants::JWT::ALGORITHM)
    end

    def decode(token)
      body = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: ApplicationConstants::JWT::ALGORITHM)[0]
      ActiveSupport::HashWithIndifferentAccess.new(body)
    rescue JWT::DecodeError => e
      raise e
    end
  end
end
