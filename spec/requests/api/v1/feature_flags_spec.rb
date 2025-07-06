require "rails_helper"

RSpec.describe "Feature Flags", type: :request do
  let(:user) { create(:user) }
  let(:editor) { create(:user, :editor) }
  let(:admin) { create(:user, :admin) }
  let(:stream) { create(:stream, user: editor) }

  describe "Stream Analytics" do
    context "when feature is disabled" do
      before { disable_feature(ApplicationConstants::Features::STREAM_ANALYTICS) }

      it "returns forbidden for analytics endpoint" do
        get "/api/v1/streams/#{stream.id}/analytics", headers: auth_headers(user)

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to eq("This feature is not currently available")
      end

      it "does not include analytics_url in stream serialization" do
        get "/api/v1/streams/#{stream.id}", headers: auth_headers(user)

        json = response.parsed_body
        expect(json).not_to have_key("analytics_url")
      end
    end

    context "when feature is enabled" do
      before { enable_feature(ApplicationConstants::Features::STREAM_ANALYTICS) }

      it "allows access to analytics endpoint" do
        get "/api/v1/streams/#{stream.id}/analytics", headers: auth_headers(user)

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json).to have_key("views_count")
        expect(json).to have_key("unique_viewers")
      end

      it "includes analytics_url in stream serialization" do
        get "/api/v1/streams/#{stream.id}", headers: auth_headers(user)

        json = response.parsed_body
        stream_data = json["stream"]
        expect(stream_data["analytics_url"]).to eq("/api/v1/streams/#{stream.id}/analytics")
      end
    end

    context "when feature is enabled for specific user" do
      before do
        disable_feature(ApplicationConstants::Features::STREAM_ANALYTICS)
        enable_feature(ApplicationConstants::Features::STREAM_ANALYTICS, editor)
      end

      it "allows access for enabled user" do
        get "/api/v1/streams/#{stream.id}/analytics", headers: auth_headers(editor)
        expect(response).to have_http_status(:success)
      end

      it "denies access for other users" do
        get "/api/v1/streams/#{stream.id}/analytics", headers: auth_headers(user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "Bulk Import" do
    let(:streams_data) do
      [
        { source: "Stream 1", link: "https://example.com/1" },
        { source: "Stream 2", link: "https://example.com/2" },
        { source: "Invalid", link: "not-a-url" },
      ]
    end

    context "when feature is disabled" do
      before { disable_feature(ApplicationConstants::Features::STREAM_BULK_IMPORT) }

      it "returns forbidden" do
        post "/api/v1/streams/bulk_import",
             params: { streams: streams_data },
             headers: auth_headers(editor)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when feature is enabled for editors group" do
      before { enable_feature_for_group(ApplicationConstants::Features::STREAM_BULK_IMPORT, :editors) }

      it "allows editors to bulk import" do
        expect do
          post "/api/v1/streams/bulk_import",
               params: { streams: streams_data },
               headers: auth_headers(editor)
        end.to change(Stream, :count).by(2)

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json["imported"]).to eq(2)
        expect(json["errors"].length).to eq(1)
      end

      it "denies default users" do
        post "/api/v1/streams/bulk_import",
             params: { streams: streams_data },
             headers: auth_headers(user)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "Export" do
    before do
      create_list(:stream, 3, user: editor, status: "live")
      create_list(:stream, 2, user: editor, status: "offline")
    end

    context "when feature is enabled" do
      before { enable_feature(ApplicationConstants::Features::STREAM_EXPORT) }

      it "exports all streams" do
        get "/api/v1/streams/export", headers: auth_headers(user)

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json["count"]).to eq(5)
        expect(json["streams"]).to be_an(Array)
      end

      it "respects filters" do
        get "/api/v1/streams/export?status=live", headers: auth_headers(user)

        json = response.parsed_body
        expect(json["count"]).to eq(3)
      end
    end
  end

  describe "Maintenance Mode" do
    context "when enabled" do
      before { enable_feature(ApplicationConstants::Features::MAINTENANCE_MODE) }
      after { disable_feature(ApplicationConstants::Features::MAINTENANCE_MODE) }

      it "blocks all API requests" do
        get "/api/v1/streams", headers: auth_headers(user)

        expect(response).to have_http_status(:service_unavailable)
        json = response.parsed_body
        expect(json["maintenance"]).to be true
      end

      it "allows health check endpoints" do
        get "/health"
        expect(response).to have_http_status(:success)

        get "/health/ready"
        expect(response).to have_http_status(:success)
      end
    end

    context "when disabled" do
      before { disable_feature(ApplicationConstants::Features::MAINTENANCE_MODE) }

      it "allows normal API access" do
        get "/api/v1/streams", headers: auth_headers(user)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "Percentage-based rollout" do
    before do
      enable_feature_for_percentage(
        ApplicationConstants::Features::AI_STREAM_RECOMMENDATIONS,
        50,
      )
    end

    it "is enabled for approximately half of users" do
      enabled_count = 0

      100.times do |i|
        test_user = create(:user, email: "test#{i}@example.com")
        enabled_count += 1 if Flipper.enabled?(ApplicationConstants::Features::AI_STREAM_RECOMMENDATIONS, test_user)
      end

      # Should be roughly 50%, allowing for some variance
      expect(enabled_count).to be_between(30, 70)
    end
  end
end
