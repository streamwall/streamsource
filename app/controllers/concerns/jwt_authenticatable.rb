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
        payload = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256')[0]
        @current_user = User.find(payload['user_id'])
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        render_unauthorized
      end
    else
      render_unauthorized
    end
  end
  
  def current_user
    @current_user
  end
  
  def extract_token_from_header
    auth_header = request.headers['Authorization']
    auth_header&.split(' ')&.last
  end
  
  def render_unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end