require "rails_helper"

RSpec.describe Api::V1::UsersController, type: :controller do
  describe "POST #signup" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          email: "newuser@example.com",
          password: "ValidPass123",
          role: "default",
        }
      end

      it "creates a new user" do
        expect do
          post :signup, params: valid_params
        end.to change(User, :count).by(1)
      end

      it "returns created status" do
        post :signup, params: valid_params
        expect(response).to have_http_status(:created)
      end

      it "returns user data and token" do
        post :signup, params: valid_params
        json = response.parsed_body

        expect(json["user"]["email"]).to eq("newuser@example.com")
        expect(json["user"]["role"]).to eq("default")
        expect(json["token"]).to be_present
      end

      it "generates valid JWT token" do
        post :signup, params: valid_params
        json = response.parsed_body

        decoded = JWT.decode(json["token"], Rails.application.secret_key_base, true, algorithm: "HS256")
        expect(decoded[0]["email"]).to eq("newuser@example.com")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          email: "invalid-email",
          password: "short",
        }
      end

      it "does not create a user" do
        expect do
          post :signup, params: invalid_params
        end.not_to change(User, :count)
      end

      it "returns unprocessable entity status" do
        post :signup, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error messages" do
        post :signup, params: invalid_params
        json = response.parsed_body

        expect(json["error"]).to include("Email is invalid")
        expect(json["error"]).to include("Password is too short")
      end
    end

    context "with duplicate email" do
      let!(:existing_user) { create(:user, email: "existing@example.com") }

      it "returns error for duplicate email" do
        post :signup, params: { email: "existing@example.com", password: "ValidPass123" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to include("Email has already been taken")
      end
    end
  end

  describe "POST #login" do
    let!(:user) { create(:user, email: "user@example.com", password: "ValidPass123") }

    context "with valid credentials" do
      it "returns success status" do
        post :login, params: { email: "user@example.com", password: "ValidPass123" }
        expect(response).to have_http_status(:success)
      end

      it "returns user data and token" do
        post :login, params: { email: "user@example.com", password: "ValidPass123" }
        json = response.parsed_body

        expect(json["user"]["email"]).to eq("user@example.com")
        expect(json["token"]).to be_present
      end

      it "is case insensitive for email" do
        post :login, params: { email: "USER@EXAMPLE.COM", password: "ValidPass123" }
        expect(response).to have_http_status(:success)
      end

      it "generates token with correct expiration" do
        post :login, params: { email: "user@example.com", password: "ValidPass123" }
        json = response.parsed_body

        decoded = JWT.decode(json["token"], Rails.application.secret_key_base, true, algorithm: "HS256")
        exp_time = Time.zone.at(decoded[0]["exp"])

        expect(exp_time).to be > Time.current
        expect(exp_time).to be < 25.hours.from_now
      end
    end

    context "with invalid credentials" do
      it "returns unauthorized for wrong password" do
        post :login, params: { email: "user@example.com", password: "wrongpassword" }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]).to eq("Invalid email or password")
      end

      it "returns unauthorized for non-existent user" do
        post :login, params: { email: "nonexistent@example.com", password: "anypassword" }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]).to eq("Invalid email or password")
      end

      it "handles nil email gracefully" do
        post :login, params: { email: nil, password: "password" }

        expect(response).to have_http_status(:unauthorized)
      end

      it "handles nil password gracefully" do
        post :login, params: { email: "user@example.com", password: nil }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "JWT token generation" do
    let(:user) { create(:user, :admin) }

    it "includes all required claims" do
      post :login, params: { email: user.email, password: "Password123!" }
      json = response.parsed_body

      decoded = JWT.decode(json["token"], Rails.application.secret_key_base, true, algorithm: "HS256")
      payload = decoded[0]

      expect(payload["user_id"]).to eq(user.id)
      expect(payload["email"]).to eq(user.email)
      expect(payload["role"]).to eq("admin")
      expect(payload["exp"]).to be_present
    end
  end
end
