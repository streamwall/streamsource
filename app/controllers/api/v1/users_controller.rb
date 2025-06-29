module Api
  module V1
    class UsersController < BaseController
      skip_before_action :authenticate_user!, only: [:signup, :login]
      
      def signup
        user = User.new(user_params)
        
        if user.save
          token = generate_jwt_token(user)
          render_success({
            user: UserSerializer.new(user),
            token: token
          }, :created)
        else
          render_error(user.errors.full_messages.join(', '), :unprocessable_entity)
        end
      end
      
      def login
        user = User.find_by(email: params[:email]&.downcase)
        
        if user && user.authenticate(params[:password])
          token = generate_jwt_token(user)
          render_success({
            user: UserSerializer.new(user),
            token: token
          })
        else
          render_error(ApplicationConstants::Messages::INVALID_CREDENTIALS, :unauthorized)
        end
      end
      
      private
      
      def user_params
        params.permit(:email, :password, :role)
      end
      
      def generate_jwt_token(user)
        payload = {
          user_id: user.id,
          email: user.email,
          role: user.role,
          exp: ApplicationConstants::JWT::EXPIRATION_TIME.from_now.to_i
        }
        
        JWT.encode(payload, Rails.application.secret_key_base, ApplicationConstants::JWT::ALGORITHM)
      end
    end
  end
end