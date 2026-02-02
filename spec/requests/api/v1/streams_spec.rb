require "rails_helper"

RSpec.describe "Api::V1::Streams", type: :request do
  let(:user) { create(:user, role: "editor") }
  let(:admin) { create(:user, role: "admin") }
  let(:default_user) { create(:user, role: "default") }

  describe "GET /api/v1/streams" do
    before do
      create(:stream, user: user, status: "live")
      create(:stream, user: user, status: "offline")
      create(:stream, user: user, is_pinned: true)
    end

    context "with valid authentication" do
      it "returns all non-archived streams" do
        get "/api/v1/streams", headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["streams"].count).to eq(3) # All non-archived streams
      end

      it "filters by status parameter" do
        get "/api/v1/streams", params: { status: "offline" }, headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["streams"].count).to eq(1)
        expect(json["streams"].first["status"]).to eq("offline")
      end
    end

    context "without authentication" do
      it "returns unauthorized" do
        get "/api/v1/streams"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/streams" do
    let(:valid_attributes) do
      { link: "https://example.com/stream", source: "Test Stream" }
    end

    context "when editor" do
      it "creates a new stream" do
        expect do
          post "/api/v1/streams", params: valid_attributes, headers: auth_headers(user)
        end.to change(Stream, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context "when default user" do
      it "returns forbidden" do
        post "/api/v1/streams", params: valid_attributes, headers: auth_headers(default_user)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
