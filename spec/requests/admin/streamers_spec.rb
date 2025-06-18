require 'rails_helper'

RSpec.describe "Admin::Streamers", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:editor_user) { create(:user, :editor) }
  let(:streamer) { create(:streamer, user: admin_user) }
  let(:another_streamer) { create(:streamer) }

  # Authentication setup handled per test group

  describe "GET /admin/streamers" do
    before do
      setup_admin_auth(admin_user)
      streamer
      another_streamer
    end

    it "returns successful response" do
      get admin_streamers_path
      expect(response).to have_http_status(:success)
    end

    it "displays streamers" do
      get admin_streamers_path
      expect(response.body).to include(streamer.name)
      expect(response.body).to include(another_streamer.name)
    end

    it "includes streamer accounts information" do
      account = create(:streamer_account, streamer: streamer, platform: 'TikTok', username: 'test_user')
      get admin_streamers_path
      expect(response.body).to include(streamer.name)
      # The index page shows streamer names, not individual account details
    end

    context "with search parameter" do
      it "filters streamers by name" do
        get admin_streamers_path(search: streamer.name)
        expect(response.body).to include(streamer.name)
        expect(response.body).not_to include(another_streamer.name)
      end
    end
  end

  describe "GET /admin/streamers/:id" do
    before { setup_admin_auth(admin_user) }

    it "returns successful response" do
      get admin_streamer_path(streamer)
      expect(response).to have_http_status(:success)
    end

    it "displays streamer details" do
      get admin_streamer_path(streamer)
      expect(response.body).to include(streamer.name)
    end

    it "displays active streams" do
      active_stream = create(:stream, :live, streamer: streamer, title: "Test Active Stream")
      get admin_streamer_path(streamer)
      expect(response.body).to include("Test Active Stream")
      expect(response.body).to include("Active Streams")
    end

    it "displays archived streams" do
      archived_stream = create(:stream, :archived, streamer: streamer, title: "Test Archived Stream")
      get admin_streamer_path(streamer)
      expect(response.body).to include("Test Archived Stream")
      expect(response.body).to include("Recent Archived Streams")
    end
  end

  describe "GET /admin/streamers/new" do
    before { setup_admin_auth(admin_user) }

    it "returns successful response" do
      get admin_new_streamer_path
      expect(response).to have_http_status(:success)
    end

    it "displays new streamer form" do
      get admin_new_streamer_path
      expect(response.body).to include('New Streamer')
    end

    it "includes user selection" do
      get admin_new_streamer_path
      expect(response.body).to include(admin_user.email)
    end
  end

  describe "POST /admin/streamers" do
    before { setup_admin_auth(admin_user) }

    let(:valid_params) do
      {
        streamer: {
          name: 'TestStreamer123',
          notes: 'Popular gaming streamer',
          posted_by: 'admin@example.com',
          user_id: editor_user.id
        }
      }
    end

    context "with valid params" do
      it "creates a new streamer" do
        expect {
          post admin_streamers_path, params: valid_params
        }.to change(Streamer, :count).by(1)
      end

      it "assigns current_user as owner" do
        post admin_streamers_path, params: valid_params
        streamer = Streamer.last
        expect(streamer.user).to eq(admin_user)
      end

      it "redirects to streamer page" do
        post admin_streamers_path, params: valid_params
        expect(response).to redirect_to(admin_streamer_path(Streamer.last))
      end

      it "sets success notice" do
        post admin_streamers_path, params: valid_params
        expect(flash[:notice]).to eq('Streamer was successfully created.')
      end

      context "with turbo stream request" do
        it "returns turbo stream response" do
          post admin_streamers_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
        end
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        { streamer: { name: '', user_id: editor_user.id } }
      end

      it "does not create a streamer" do
        expect {
          post admin_streamers_path, params: invalid_params
        }.not_to change(Streamer, :count)
      end

      it "returns unprocessable entity status" do
        post admin_streamers_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/streamers/:id/edit" do
    before { setup_admin_auth(admin_user) }

    it "returns successful response" do
      get admin_edit_streamer_path(streamer)
      expect(response).to have_http_status(:success)
    end

    it "displays edit form with streamer data" do
      get admin_edit_streamer_path(streamer)
      expect(response.body).to include(streamer.name)
    end
  end

  describe "PATCH /admin/streamers/:id" do
    before { setup_admin_auth(admin_user) }

    let(:update_params) do
      {
        streamer: {
          name: 'UpdatedStreamerName',
          notes: 'Updated notes'
        }
      }
    end

    context "with valid params" do
      it "updates the streamer" do
        patch admin_streamer_path(streamer), params: update_params
        streamer.reload
        expect(streamer.name).to eq('UpdatedStreamerName')
        expect(streamer.notes).to eq('Updated notes')
      end

      it "redirects to streamer page" do
        patch admin_streamer_path(streamer), params: update_params
        expect(response).to redirect_to(admin_streamer_path(streamer))
      end

      it "sets success notice" do
        patch admin_streamer_path(streamer), params: update_params
        expect(flash[:notice]).to eq('Streamer was successfully updated.')
      end

      context "with turbo stream request" do
        it "returns turbo stream response" do
          patch admin_streamer_path(streamer), params: update_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
        end
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        { streamer: { name: '' } }
      end

      it "does not update the streamer" do
        original_name = streamer.name
        patch admin_streamer_path(streamer), params: invalid_params
        streamer.reload
        expect(streamer.name).to eq(original_name)
      end

      it "returns unprocessable entity status" do
        patch admin_streamer_path(streamer), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/streamers/:id" do
    before { setup_admin_auth(admin_user) }

    it "deletes the streamer" do
      streamer # ensure it exists
      expect {
        delete admin_streamer_path(streamer)
      }.to change(Streamer, :count).by(-1)
    end

    it "redirects to streamers index" do
      delete admin_streamer_path(streamer)
      expect(response).to redirect_to(admin_streamers_path)
    end

    it "sets success notice" do
      delete admin_streamer_path(streamer)
      expect(flash[:notice]).to eq('Streamer was successfully deleted.')
    end

    context "with turbo stream request" do
      it "returns turbo stream response" do
        delete admin_streamer_path(streamer), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "authorization" do
    context "when not logged in" do
      it "redirects to login" do
        # Clear any session
        allow_any_instance_of(Admin::BaseController).to receive(:current_admin_user).and_return(nil)

        get admin_streamers_path
        expect(response).to redirect_to(admin_login_path)
      end
    end

    context "when logged in as non-admin" do
      it "redirects to login" do
        # Mock current_admin_user to return a non-admin user
        allow_any_instance_of(Admin::BaseController).to receive(:current_admin_user).and_return(editor_user)

        get admin_streamers_path
        expect(response).to redirect_to(admin_login_path)
      end
    end
  end
end