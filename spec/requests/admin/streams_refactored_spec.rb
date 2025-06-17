require 'rails_helper'

RSpec.describe "Admin::Streams", type: :request do
  include_context "with admin authentication"
  include_context "with sample resources"
  
  let(:index_path) { admin_streams_path }
  let(:show_path) { admin_stream_path(user_stream) }
  let(:new_path) { admin_new_stream_path }
  let(:create_path) { admin_streams_path }
  let(:valid_params) do
    {
      stream: {
        source: 'TestStreamer',
        link: 'https://tiktok.com/@teststreamer/live',
        user_id: user.id,
        platform: 'TikTok',
        status: 'Live'
      }
    }
  end
  
  it_behaves_like "admin crud authorization"
  
  describe "GET /admin/streams" do
    it "returns successful response" do
      get admin_streams_path
      expect_admin_page_success
    end
    
    it "displays streams" do
      get admin_streams_path
      expect_admin_page_to_include(user_stream.source, another_user_stream.source)
    end
    
    context "with filters" do
      it "filters by status" do
        get admin_streams_path(status: 'Live')
        expect_admin_page_to_include(user_stream.source)
        expect_admin_page_not_to_include(offline_stream.source)
      end
      
      it "filters by platform" do
        tiktok_stream = create(:stream, platform: 'TikTok')
        youtube_stream = create(:stream, platform: 'YouTube')
        
        get admin_streams_path(platform: 'TikTok')
        expect_admin_page_to_include(tiktok_stream.source)
        expect_admin_page_not_to_include(youtube_stream.source)
      end
    end
  end
  
  describe "GET /admin/streams/:id" do
    it "returns successful response" do
      get admin_stream_path(user_stream)
      expect_admin_page_success
    end
    
    it "displays stream details" do
      get admin_stream_path(user_stream)
      expect_admin_page_to_include(user_stream.source, user_stream.link)
    end
  end
  
  describe "POST /admin/streams" do
    context "with valid params" do
      it "creates stream" do
        expect {
          post admin_streams_path, params: valid_params
        }.to change(Stream, :count).by(1)
      end
      
      it "redirects to index" do
        post admin_streams_path, params: valid_params
        expect_admin_redirect_to(admin_streams_path)
      end
    end
    
    context "with invalid params" do
      let(:invalid_params) { { stream: { source: '', link: '' } } }
      
      it "does not create stream" do
        expect {
          post admin_streams_path, params: invalid_params
        }.not_to change(Stream, :count)
      end
      
      it "returns unprocessable entity" do
        post admin_streams_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  
  describe "PATCH /admin/streams/:id/toggle_pin" do
    it "toggles pin status" do
      expect_to_change_value(user_stream, :is_pinned, from: false, to: true) do
        patch admin_toggle_pin_stream_path(user_stream)
      end
    end
    
    it "redirects to streams index" do
      patch admin_toggle_pin_stream_path(user_stream)
      expect_admin_redirect_to(admin_streams_path)
    end
  end
  
  describe "DELETE /admin/streams/:id" do
    let!(:stream_to_delete) { create(:stream) }
    
    it "deletes stream" do
      expect {
        delete admin_stream_path(stream_to_delete)
      }.to change(Stream, :count).by(-1)
    end
    
    it "redirects to index" do
      delete admin_stream_path(stream_to_delete)
      expect_admin_redirect_to(admin_streams_path)
    end
  end
end