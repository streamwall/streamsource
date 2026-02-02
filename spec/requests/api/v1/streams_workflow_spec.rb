require "rails_helper"

RSpec.describe "Streams Workflow", type: :request do
  let(:default_user) { create(:user) }
  let(:editor) { create(:user, :editor) }
  let(:admin) { create(:user, :admin) }
  let(:headers) { auth_headers(editor) }

  describe "complete stream lifecycle" do
    let(:stream_params) { { source: "Test Stream", link: "https://example.com/test" } }

    it "creates a stream" do
      post "/api/v1/streams", params: stream_params, headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["stream"]).to include(
        "source" => "Test Stream",
        "status" => "unknown",
        "is_pinned" => false,
      )
    end

    it "reads a stream" do
      stream = create(:stream, user: editor)
      get "/api/v1/streams/#{stream.id}", headers: headers

      expect(response).to have_http_status(:success)
      expect(response.parsed_body["stream"]["id"]).to eq(stream.id)
    end

    it "updates a stream" do
      stream = create(:stream, user: editor)
      patch "/api/v1/streams/#{stream.id}",
            params: { source: "Updated Stream", status: "offline" },
            headers: headers

      expect(response).to have_http_status(:success)
      expect(response.parsed_body["stream"]).to include(
        "source" => "Updated Stream",
        "status" => "offline",
      )
    end

    it "pins a stream" do
      stream = create(:stream, user: editor)
      put "/api/v1/streams/#{stream.id}/pin", headers: headers

      expect(response).to have_http_status(:success)
      expect(response.parsed_body["stream"]["is_pinned"]).to be true
    end

    it "unpinns a stream" do
      stream = create(:stream, user: editor, is_pinned: true)
      delete "/api/v1/streams/#{stream.id}/pin", headers: headers

      expect(response).to have_http_status(:success)
      expect(response.parsed_body["stream"]["is_pinned"]).to be false
    end

    it "deletes a stream" do
      stream = create(:stream, user: editor)
      delete "/api/v1/streams/#{stream.id}", headers: headers

      expect(response).to have_http_status(:no_content)

      get "/api/v1/streams/#{stream.id}", headers: headers
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

    it "paginates first page" do
      get "/api/v1/streams",
          params: { per_page: 5, page: 1 },
          headers: headers

      json = response.parsed_body
      expect(json["streams"].length).to eq(5)
      expect(json["meta"]).to include("current_page" => 1, "total_count" => 9)
    end

    it "paginates second page" do
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

      expect(response).to have_http_status(:unprocessable_content)
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
