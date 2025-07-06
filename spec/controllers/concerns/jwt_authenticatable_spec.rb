require "rails_helper"

RSpec.describe JwtAuthenticatable do
  let(:user) { create(:user) }

  controller(ApplicationController) do
    def index
      render json: { user_id: current_user&.id }
    end
  end

  describe "#authenticate_user!" do
    context "with valid token" do
      it "sets current_user" do
        request.headers.merge!(auth_headers(user))
        get :index

        expect(response).to have_http_status(:success)
        expect(response.parsed_body["user_id"]).to eq(user.id)
      end
    end

    context "with expired token" do
      it "returns unauthorized" do
        request.headers.merge!(expired_auth_headers(user))
        get :index

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]).to eq("Unauthorized")
      end
    end

    context "with invalid token" do
      it "returns unauthorized" do
        request.headers.merge!(invalid_auth_headers)
        get :index

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]).to eq("Unauthorized")
      end
    end

    context "with malformed authorization header" do
      it "returns unauthorized for missing Bearer prefix" do
        request.headers["Authorization"] = generate_jwt_token(user)
        get :index

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns unauthorized for empty token" do
        request.headers["Authorization"] = "Bearer "
        get :index

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "without authorization header" do
      it "returns unauthorized" do
        get :index

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]).to eq("Unauthorized")
      end
    end

    context "with deleted user" do
      it "returns unauthorized" do
        request.headers.merge!(auth_headers(user))
        user.destroy
        get :index

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "#current_user" do
    controller(ApplicationController) do
      skip_before_action :authenticate_user!

      def index
        render json: {
          has_user: current_user.present?,
          user_email: current_user&.email,
        }
      end
    end

    it "returns nil without authentication" do
      get :index

      json = response.parsed_body
      expect(json["has_user"]).to be false
      expect(json["user_email"]).to be_nil
    end

    it "returns user with valid authentication" do
      request.headers.merge!(auth_headers(user))
      get :index

      json = response.parsed_body
      expect(json["has_user"]).to be true
      expect(json["user_email"]).to eq(user.email)
    end
  end

  describe "#extract_token_from_header" do
    controller(ApplicationController) do
      skip_before_action :authenticate_user!

      def index
        token = extract_token_from_header
        render json: { token: token }
      end
    end

    it "extracts token from valid header" do
      request.headers["Authorization"] = "Bearer test.token.here"
      get :index

      expect(response.parsed_body["token"]).to eq("test.token.here")
    end

    it "returns last part when multiple spaces" do
      request.headers["Authorization"] = "Bearer  multiple  spaces  token"
      get :index

      expect(response.parsed_body["token"]).to eq("token")
    end

    it "handles nil authorization header" do
      get :index

      expect(response.parsed_body["token"]).to be_nil
    end
  end

  describe "JWT token validation" do
    it "validates algorithm" do
      # Create token with wrong algorithm
      payload = { user_id: user.id, exp: 1.hour.from_now.to_i }
      wrong_algo_token = JWT.encode(payload, Rails.application.secret_key_base, "HS512")

      request.headers["Authorization"] = "Bearer #{wrong_algo_token}"
      get :index

      expect(response).to have_http_status(:unauthorized)
    end

    it "validates secret key" do
      # Create token with wrong secret
      payload = { user_id: user.id, exp: 1.hour.from_now.to_i }
      wrong_secret_token = JWT.encode(payload, "wrong_secret", "HS256")

      request.headers["Authorization"] = "Bearer #{wrong_secret_token}"
      get :index

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
