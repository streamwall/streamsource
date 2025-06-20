require 'rails_helper'

RSpec.describe "Admin::Timestamps", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  
  before do
    # Set a valid host for tests
    host! 'test.example.com'
    
    # Disable maintenance mode for tests
    allow(Flipper).to receive(:enabled?).with(ApplicationConstants::Features::MAINTENANCE_MODE).and_return(false)
  end
  
  # Helper method to log in admin user
  def login_admin
    setup_admin_auth(admin_user)
  end
  
  describe "GET /admin/timestamps" do
    let!(:timestamps) { create_list(:timestamp, 3, user: admin_user) }
    
    before { login_admin }
    
    it "returns successful response" do
      get admin_timestamps_path
      expect(response).to have_http_status(:success)
    end
    
    it "displays timestamps" do
      get admin_timestamps_path
      timestamps.each do |timestamp|
        expect(response.body).to include(timestamp.title)
      end
    end
    
    context "with filters" do
      it "filters by search term" do
        searchable = create(:timestamp, title: 'Earthquake in California')
        get admin_timestamps_path(search: 'earthquake')
        expect(response.body).to include(searchable.title)
      end
    end
    
    context "with turbo stream request" do
      it "returns turbo stream response" do
        get admin_timestamps_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end
  end
  
  describe "GET /admin/timestamps/:id" do
    let(:timestamp) { create(:timestamp, user: admin_user) }
    let!(:timestamp_stream) { create(:timestamp_stream, timestamp: timestamp) }
    
    before { login_admin }
    
    it "returns successful response" do
      get admin_timestamp_path(timestamp)
      expect(response).to have_http_status(:success)
    end
    
    it "displays timestamp details" do
      get admin_timestamp_path(timestamp)
      expect(response.body).to include(timestamp.title)
    end
    
    it "displays linked streams" do
      get admin_timestamp_path(timestamp)
      expect(response.body).to include(timestamp_stream.stream.source)
    end
  end
  
  describe "GET /admin/timestamps/new" do
    before { login_admin }
    
    it "returns successful response" do
      get new_admin_timestamp_path
      expect(response).to have_http_status(:success)
    end
    
    it "displays form" do
      get new_admin_timestamp_path
      expect(response.body).to include('form')
      expect(response.body).to include('Event Title')
    end
  end
  
  describe "POST /admin/timestamps" do
    before { login_admin }
    
    let(:valid_params) do
      {
        timestamp: {
          title: 'Major Earthquake',
          event_timestamp: Time.current,
          description: 'A major earthquake has struck the region'
        }
      }
    end
    
    context "with valid params" do
      it "creates timestamp" do
        expect {
          post admin_timestamps_path, params: valid_params
        }.to change(Timestamp, :count).by(1)
      end
      
      it "redirects to index" do
        post admin_timestamps_path, params: valid_params
        expect(response).to redirect_to(admin_timestamps_path)
      end
      
      it "sets current user as creator" do
        post admin_timestamps_path, params: valid_params
        expect(Timestamp.last.user).to eq(admin_user)
      end
      
      context "with turbo stream request" do
        it "returns turbo stream response" do
          post admin_timestamps_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.content_type).to include("text/vnd.turbo-stream.html")
        end
      end
    end
    
    context "with invalid params" do
      let(:invalid_params) do
        { timestamp: { title: '' } }
      end
      
      it "does not create timestamp" do
        expect {
          post admin_timestamps_path, params: invalid_params
        }.not_to change(Timestamp, :count)
      end
      
      it "returns unprocessable entity" do
        post admin_timestamps_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  
  describe "GET /admin/timestamps/:id/edit" do
    let(:timestamp) { create(:timestamp, user: admin_user) }
    
    before { login_admin }
    
    it "returns successful response" do
      get edit_admin_timestamp_path(timestamp)
      expect(response).to have_http_status(:success)
    end
    
    it "displays form with timestamp data" do
      get edit_admin_timestamp_path(timestamp)
      expect(response.body).to include(timestamp.title)
    end
  end
  
  describe "PATCH /admin/timestamps/:id" do
    let(:timestamp) { create(:timestamp, user: admin_user) }
    
    before { login_admin }
    
    let(:update_params) do
      {
        timestamp: {
          title: 'Updated Title'
        }
      }
    end
    
    context "with valid params" do
      it "updates timestamp" do
        patch admin_timestamp_path(timestamp), params: update_params
        timestamp.reload
        expect(timestamp.title).to eq('Updated Title')
      end
      
      it "redirects to show page" do
        patch admin_timestamp_path(timestamp), params: update_params
        expect(response).to redirect_to(admin_timestamp_path(timestamp))
      end
    end
    
    context "with invalid params" do
      let(:invalid_params) do
        { timestamp: { title: '' } }
      end
      
      it "does not update timestamp" do
        original_title = timestamp.title
        patch admin_timestamp_path(timestamp), params: invalid_params
        timestamp.reload
        expect(timestamp.title).to eq(original_title)
      end
    end
  end
  
  describe "DELETE /admin/timestamps/:id" do
    let!(:timestamp) { create(:timestamp, user: admin_user) }
    
    before { login_admin }
    
    it "deletes timestamp" do
      expect {
        delete admin_timestamp_path(timestamp)
      }.to change(Timestamp, :count).by(-1)
    end
    
    it "redirects to index" do
      delete admin_timestamp_path(timestamp)
      expect(response).to redirect_to(admin_timestamps_path)
    end
    
    context "with turbo stream request" do
      it "returns turbo stream response" do
        delete admin_timestamp_path(timestamp), headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end
  end
  
  
  describe "POST /admin/timestamps/:id/add_stream" do
    let(:timestamp) { create(:timestamp, user: admin_user) }
    let(:stream) { create(:stream) }
    
    before { login_admin }
    
    let(:params) do
      {
        stream_id: stream.id,
        timestamp_seconds: 120
      }
    end
    
    it "adds stream to timestamp" do
      expect {
        post add_stream_admin_timestamp_path(timestamp), params: params
      }.to change(timestamp.timestamp_streams, :count).by(1)
    end
    
    it "creates timestamp_stream with correct attributes" do
      post add_stream_admin_timestamp_path(timestamp), params: params
      timestamp_stream = timestamp.timestamp_streams.last
      
      expect(timestamp_stream.stream).to eq(stream)
      expect(timestamp_stream.stream_timestamp_seconds).to eq(120)
      expect(timestamp_stream.added_by_user).to eq(admin_user)
    end
    
    it "redirects to show page" do
      post add_stream_admin_timestamp_path(timestamp), params: params
      expect(response).to redirect_to(admin_timestamp_path(timestamp))
    end
  end
  
  describe "authorization" do
    it "redirects non-admin users" do
      # Don't set up admin auth for this test
      get admin_timestamps_path
      expect(response).to redirect_to(admin_login_path)
    end
  end
end