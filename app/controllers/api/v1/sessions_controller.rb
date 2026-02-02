module Api
  module V1
    # API endpoints for authentication sessions.
    class SessionsController < BaseController
      skip_before_action :authenticate_user!, only: %i[create destroy]

      def create
        user = User.find_by(email: params.dig(:user, :email))

        if user&.valid_password?(params.dig(:user, :password))
          # Generate JWT token using our custom payload method
          token_payload = user.jwt_payload
          token = JWT.encode(token_payload, Rails.application.secret_key_base, "HS256")

          serializer = UserSerializer.new(user)
          user_data = serializer.serializable_hash

          render json: {
            status: { code: 200, message: "Logged in successfully." },
            user: user_data[:data] ? user_data[:data][:attributes] : user_data,
            token: token,
          }, status: :ok
        else
          render json: {
            error: "Invalid email or password",
          }, status: :unauthorized
        end
      end

      def destroy
        # For JWT, logout is typically handled client-side by discarding the token
        render json: {
          status: 200,
          message: "Logged out successfully.",
        }, status: :ok
      end
    end
  end
end
