module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    # Let Devise handle authentication
    before_action :authenticate_user!
  end

  private

  # Override Devise's authenticate_user! to handle JWT tokens
  def authenticate_user!
    if request.headers['Authorization'].present?
      authenticate_with_jwt
    else
      render_unauthorized
    end
  end

  def authenticate_with_jwt
    begin
      jwt_payload = decode_jwt_token
      user_id = jwt_payload['sub'] || jwt_payload['user_id']
      @current_user = User.find(user_id)
      
      # Check if token is revoked (if jti is present)
      jti = jwt_payload['jti']
      if jti && JwtDenylist.exists?(jti: jti)
        render_unauthorized
        return
      end
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render_unauthorized
    end
  end

  def decode_jwt_token
    auth_header = request.headers['Authorization']
    token = auth_header.split(' ').last
    
    # Try with Devise JWT secret first
    begin
      JWT.decode(token, Rails.application.credentials.devise&.dig(:jwt_secret_key) || Rails.application.secret_key_base, true, algorithm: 'HS256')[0]
    rescue JWT::DecodeError
      # Fall back to standard secret
      JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256')[0]
    end
  end

  def current_user
    @current_user
  end

  def render_unauthorized
    render json: { error: ApplicationConstants::Messages::UNAUTHORIZED }, status: :unauthorized
  end
end