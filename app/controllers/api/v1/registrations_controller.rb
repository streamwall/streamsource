module Api
  module V1
    # API endpoints for user registration.
    class RegistrationsController < Devise::RegistrationsController
      skip_before_action :verify_authenticity_token
      respond_to :json

      private

      def respond_with(resource, _opts = {})
        if resource.persisted?
          render json: {
            status: { code: 200, message: "Signed up successfully." },
            data: UserSerializer.new(resource).serializable_hash[:data][:attributes],
          }
        else
          render json: {
            status: { message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}" },
          }, status: :unprocessable_content
        end
      end

      def sign_up_params
        params.expect(user: %i[email password password_confirmation])
      end
    end
  end
end
