require "rails_helper"

RSpec.describe "Streams Workflow", type: :request do
  let(:default_user) { create(:user) }
  let(:editor) { create(:user, :editor) }
  let(:admin) { create(:user, :admin) }
  let(:headers) { auth_headers(editor) }

  describe "complete stream lifecycle" do
    it "allows CRUD operations on streams" do
      # Create a stream
      post "/api/v1/streams",
           params: { source: "Test Stream", link: "https://example.com/test" },
           headers: headers

      expect(response).to have_http_status(:created)
      stream = response.parsed_body["stream"]
      stream_id = stream["id"]
      expect(stream["source"]).to eq("Test Stream")
      expect(stream["status"]).to eq("unknown")
      expect(stream["is_pinned"]).to be false

      # Read the stream
      get "/api/v1/streams/#{stream_id}", headers: headers

      expect(response).to have_http_status(:success)
      expect(response.parsed_body["stream"]["id"]).to eq(stream_id)

      # Update the stream
      patch "/api/v1/streams/#{stream_id}",
            params: { source: "Updated Stream", status: "offline" },
            headers: headers

      expect(response).to have_http_status(:success)
      updated = response.parsed_body["stream"]
      expect(updated["source"]).to eq("Updated Stream")
      expect(updated["status"]).to eq("offline")

      # Pin the stream
      put "/api/v1/streams/#{stream_id}/pin", headers: headers

      expect(response).to have_http_status(:success)
      expect(response.parsed_body["stream"]["is_pinned"]).to be true

      # Unpin the stream
      delete "/api/v1/streams/#{stream_id}/pin", headers: headers

      expect(response).to have_http_status(:success)
      expect(response.parsed_body["stream"]["is_pinned"]).to be false

      # Delete the stream
      delete "/api/v1/streams/#{stream_id}", headers: headers

      expect(response).to have_http_status(:no_content)

      # Verify deletion
      get "/api/v1/streams/#{stream_id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "authorization rules" do
    let!(:editor_stream) { create(:stream, user: editor) }
    let!(:other_stream) { create(:stream) }

    it "enforces create permissions" do
      # Default user cannot create
      post "/api/v1/streams",
           params: { source: "Test", link: "https://test.com" },
           headers: auth_headers(default_user)

      expect(response).to have_http_status(:forbidden)

      # Editor can create
      post "/api/v1/streams",
           params: { source: "Test", link: "https://test.com" },
           headers: auth_headers(editor)

      expect(response).to have_http_status(:created)
    end

    it "enforces update permissions" do
      # Editor can update own stream
      patch "/api/v1/streams/#{editor_stream.id}",
            params: { source: "Updated" },
            headers: auth_headers(editor)

      expect(response).to have_http_status(:success)

      # Editor cannot update others stream
      patch "/api/v1/streams/#{other_stream.id}",
            params: { source: "Updated" },
            headers: auth_headers(editor)

      expect(response).to have_http_status(:forbidden)

      # Admin can update any stream
      patch "/api/v1/streams/#{other_stream.id}",
            params: { source: "Admin Updated" },
            headers: auth_headers(admin)

      expect(response).to have_http_status(:success)
    end
  end

  describe "filtering and pagination" do
    before do
      create_list(:stream, 5, user: editor, status: "live")
      create_list(:stream, 3, user: editor, status: "offline")
      create(:stream, user: editor, is_pinned: true)
    end

    it "filters by status" do
      get "/api/v1/streams",
          params: { status: "live" },
          headers: headers

      json = response.parsed_body
      expect(json["streams"].all? { |s| s["status"] == "live" }).to be true
    end

    it "filters by notStatus" do
      get "/api/v1/streams",
          params: { notStatus: "offline" },
          headers: headers

      json = response.parsed_body
      expect(json["streams"].none? { |s| s["status"] == "offline" }).to be true
    end

    it "filters by is_pinned" do
      get "/api/v1/streams",
          params: { is_pinned: true },
          headers: headers

      json = response.parsed_body
      expect(json["streams"].all? { |s| s["is_pinned"] == true }).to be true
      expect(json["streams"].length).to eq(1)
    end

    it "paginates results" do
      get "/api/v1/streams",
          params: { per_page: 5, page: 1 },
          headers: headers

      json = response.parsed_body
      expect(json["streams"].length).to eq(5)
      expect(json["meta"]["current_page"]).to eq(1)
      expect(json["meta"]["total_count"]).to eq(9)

      # Get second page
      get "/api/v1/streams",
          params: { per_page: 5, page: 2 },
          headers: headers

      json = response.parsed_body
      expect(json["streams"].length).to eq(4)
      expect(json["meta"]["current_page"]).to eq(2)
    end

    it "orders pinned streams first" do
      get "/api/v1/streams", headers: headers

      json = response.parsed_body
      expect(json["streams"].first["is_pinned"]).to be true
    end
  end

  describe "error handling" do
    it "returns proper error for invalid stream data" do
      post "/api/v1/streams",
           params: { source: "", link: "not-a-url" },
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      error = response.parsed_body["error"]
      expect(error).to include("Source can't be blank")
      expect(error).to include("Link must be a valid HTTP or HTTPS URL")
    end

    it "returns 404 for non-existent stream" do
      get "/api/v1/streams/99999", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
