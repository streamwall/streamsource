module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    token = extract_token_from_header

    if token
      begin
        payload = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: ApplicationConstants::JWT::ALGORITHM)[0]
        @current_user = User.find(payload["user_id"])
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        render_unauthorized
      end
    else
      render_unauthorized
    end
  end

  def current_user
    return @current_user if defined?(@current_user)

    # Try to authenticate if not already done
    token = extract_token_from_header
    if token
      begin
        payload = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: ApplicationConstants::JWT::ALGORITHM)[0]
        @current_user = User.find_by(id: payload["user_id"])
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        @current_user = nil
      end
    else
      @current_user = nil
    end

    @current_user
  end

  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    return nil unless auth_header&.start_with?("Bearer ")

    auth_header.split.last
  end

  def render_unauthorized
    render json: { error: ApplicationConstants::Messages::UNAUTHORIZED }, status: :unauthorized
  end
end
