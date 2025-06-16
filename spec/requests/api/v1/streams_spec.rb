require 'rails_helper'

RSpec.describe "Api::V1::Streams", type: :request do
  let(:user) { create(:user, role: 'editor') }
  let(:admin) { create(:user, role: 'admin') }
  let(:default_user) { create(:user, role: 'default') }
  let(:auth_headers) { { 'Authorization' => "Bearer #{generate_jwt_token(user)}" } }
  
  def generate_jwt_token(user)
    payload = {
      user_id: user.id,
      email: user.email,
      role: user.role,
      exp: 24.hours.from_now.to_i
    }
    
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end
  
  describe "GET /api/v1/streams" do
    let!(:active_stream) { create(:stream, user: user, status: 'active') }
    let!(:inactive_stream) { create(:stream, user: user, status: 'inactive') }
    let!(:pinned_stream) { create(:stream, user: user, is_pinned: true) }
    
    context "with valid authentication" do
      it "returns all active streams" do
        get "/api/v1/streams", headers: auth_headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['streams'].count).to eq(2) # Only active streams
      end
      
      it "filters by status parameter" do
        get "/api/v1/streams", params: { status: 'inactive' }, headers: auth_headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['streams'].count).to eq(1)
        expect(json['streams'].first['status']).to eq('inactive')
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
    let(:valid_attributes) {
      { url: 'https://example.com/stream', name: 'Test Stream' }
    }
    
    context "as editor" do
      it "creates a new stream" do
        expect {
          post "/api/v1/streams", params: valid_attributes, headers: auth_headers
        }.to change(Stream, :count).by(1)
        
        expect(response).to have_http_status(:created)
      end
    end
    
    context "as default user" do
      let(:auth_headers) { { 'Authorization' => "Bearer #{generate_jwt_token(default_user)}" } }
      
      it "returns forbidden" do
        post "/api/v1/streams", params: valid_attributes, headers: auth_headers
        
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end