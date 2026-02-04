require "rails_helper"

RSpec.describe "Admin::Streams", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  before do
    sign_in_admin(admin_user)
  end

  describe "GET /admin/streams" do
    let!(:streams) { create_list(:stream, 3) }

    it "returns successful response" do
      get admin_streams_path
      expect(response).to have_http_status(:success)
    end

    it "displays streams" do
      get admin_streams_path
      streams.each do |stream|
        expect(response.body).to include(stream.source)
      end
    end

    context "with filters" do
      let!(:live_stream) { create(:stream, status: "Live", platform: "TikTok") }
      let!(:offline_stream) { create(:stream, status: "Offline", platform: "YouTube") }

      it "filters by status" do
        get admin_streams_path(status: "Live")
        expect(response.body).to include("stream_#{live_stream.id}")
        expect(response.body).not_to include("stream_#{offline_stream.id}")
      end

      it "filters by platform" do
        get admin_streams_path(platform: "TikTok")
        expect(response.body).to include("stream_#{live_stream.id}")
        expect(response.body).not_to include("stream_#{offline_stream.id}")
      end
    end
  end

  describe "GET /admin/streams/:id" do
    let(:stream) { create(:stream) }

    it "returns successful response" do
      get admin_stream_path(stream)
      expect(response).to have_http_status(:success)
    end

    it "displays stream details" do
      get admin_stream_path(stream)
      expect(response.body).to include(stream.source)
      expect(response.body).to include(stream.link)
    end
  end

  describe "GET /admin/streams/new" do
    it "returns successful response" do
      get admin_new_stream_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/streams" do
    let(:valid_params) do
      {
        stream: {
          source: "TestStreamer",
          link: "https://tiktok.com/@teststreamer/live",
          user_id: regular_user.id,
          platform: "TikTok",
          status: "Live",
        },
      }
    end

    context "with valid params" do
      it "creates stream" do
        expect do
          post admin_streams_path, params: valid_params
        end.to change(Stream, :count).by(1)
      end

      it "redirects to index" do
        post admin_streams_path, params: valid_params
        expect(response).to redirect_to(admin_streams_path)
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        { stream: { source: "", link: "" } }
      end

      it "does not create stream" do
        expect do
          post admin_streams_path, params: invalid_params
        end.not_to change(Stream, :count)
      end

      it "returns unprocessable entity" do
        post admin_streams_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /admin/streams/:id/toggle_pin" do
    let(:stream) { create(:stream, is_pinned: false) }

    it "toggles pin status" do
      expect do
        patch admin_toggle_pin_stream_path(stream)
      end.to change { stream.reload.is_pinned }.from(false).to(true)
    end

    it "redirects to streams index" do
      patch admin_toggle_pin_stream_path(stream)
      expect(response).to redirect_to(admin_streams_path)
    end
  end

  describe "DELETE /admin/streams/:id" do
    let!(:stream) { create(:stream) }

    it "deletes stream" do
      expect do
        delete admin_stream_path(stream)
      end.to change(Stream, :count).by(-1)
    end

    it "redirects to index" do
      delete admin_stream_path(stream)
      expect(response).to redirect_to(admin_streams_path)
    end
  end
end
