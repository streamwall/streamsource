require 'rails_helper'

RSpec.describe 'Streams Workflow', type: :request do
  let(:default_user) { create(:user) }
  let(:editor) { create(:user, :editor) }
  let(:admin) { create(:user, :admin) }
  let(:headers) { auth_headers(editor) }
  
  describe 'complete stream lifecycle' do
    it 'allows CRUD operations on streams' do
      # Create a stream
      post '/api/v1/streams',
        params: { name: 'Test Stream', url: 'https://example.com/test' },
        headers: headers
      
      expect(response).to have_http_status(:created)
      stream = JSON.parse(response.body)
      stream_id = stream['id']
      expect(stream['name']).to eq('Test Stream')
      expect(stream['status']).to eq('active')
      expect(stream['is_pinned']).to be false
      
      # Read the stream
      get "/api/v1/streams/#{stream_id}", headers: headers
      
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['id']).to eq(stream_id)
      
      # Update the stream
      patch "/api/v1/streams/#{stream_id}",
        params: { name: 'Updated Stream', status: 'inactive' },
        headers: headers
      
      expect(response).to have_http_status(:success)
      updated = JSON.parse(response.body)
      expect(updated['name']).to eq('Updated Stream')
      expect(updated['status']).to eq('inactive')
      
      # Pin the stream
      put "/api/v1/streams/#{stream_id}/pin", headers: headers
      
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['is_pinned']).to be true
      
      # Unpin the stream
      delete "/api/v1/streams/#{stream_id}/pin", headers: headers
      
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['is_pinned']).to be false
      
      # Delete the stream
      delete "/api/v1/streams/#{stream_id}", headers: headers
      
      expect(response).to have_http_status(:no_content)
      
      # Verify deletion
      get "/api/v1/streams/#{stream_id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
  
  describe 'authorization rules' do
    let!(:editor_stream) { create(:stream, user: editor) }
    let!(:other_stream) { create(:stream) }
    
    it 'enforces create permissions' do
      # Default user cannot create
      post '/api/v1/streams',
        params: { name: 'Test', url: 'https://test.com' },
        headers: auth_headers(default_user)
      
      expect(response).to have_http_status(:forbidden)
      
      # Editor can create
      post '/api/v1/streams',
        params: { name: 'Test', url: 'https://test.com' },
        headers: auth_headers(editor)
      
      expect(response).to have_http_status(:created)
    end
    
    it 'enforces update permissions' do
      # Editor can update own stream
      patch "/api/v1/streams/#{editor_stream.id}",
        params: { name: 'Updated' },
        headers: auth_headers(editor)
      
      expect(response).to have_http_status(:success)
      
      # Editor cannot update others stream
      patch "/api/v1/streams/#{other_stream.id}",
        params: { name: 'Updated' },
        headers: auth_headers(editor)
      
      expect(response).to have_http_status(:forbidden)
      
      # Admin can update any stream
      patch "/api/v1/streams/#{other_stream.id}",
        params: { name: 'Admin Updated' },
        headers: auth_headers(admin)
      
      expect(response).to have_http_status(:success)
    end
  end
  
  describe 'filtering and pagination' do
    before do
      create_list(:stream, 5, user: editor, status: 'active')
      create_list(:stream, 3, user: editor, status: 'inactive')
      create(:stream, user: editor, is_pinned: true)
    end
    
    it 'filters by status' do
      get '/api/v1/streams',
        params: { status: 'active' },
        headers: headers
      
      json = JSON.parse(response.body)
      expect(json['streams'].all? { |s| s['status'] == 'active' }).to be true
    end
    
    it 'filters by notStatus' do
      get '/api/v1/streams',
        params: { notStatus: 'inactive' },
        headers: headers
      
      json = JSON.parse(response.body)
      expect(json['streams'].none? { |s| s['status'] == 'inactive' }).to be true
    end
    
    it 'filters by is_pinned' do
      get '/api/v1/streams',
        params: { is_pinned: true },
        headers: headers
      
      json = JSON.parse(response.body)
      expect(json['streams'].all? { |s| s['is_pinned'] == true }).to be true
      expect(json['streams'].length).to eq(1)
    end
    
    it 'paginates results' do
      get '/api/v1/streams',
        params: { per_page: 5, page: 1 },
        headers: headers
      
      json = JSON.parse(response.body)
      expect(json['streams'].length).to eq(5)
      expect(json['meta']['current_page']).to eq(1)
      expect(json['meta']['total_count']).to eq(9)
      
      # Get second page
      get '/api/v1/streams',
        params: { per_page: 5, page: 2 },
        headers: headers
      
      json = JSON.parse(response.body)
      expect(json['streams'].length).to eq(4)
      expect(json['meta']['current_page']).to eq(2)
    end
    
    it 'orders pinned streams first' do
      get '/api/v1/streams', headers: headers
      
      json = JSON.parse(response.body)
      expect(json['streams'].first['is_pinned']).to be true
    end
  end
  
  describe 'error handling' do
    it 'returns proper error for invalid stream data' do
      post '/api/v1/streams',
        params: { name: '', url: 'not-a-url' },
        headers: headers
      
      expect(response).to have_http_status(:unprocessable_entity)
      error = JSON.parse(response.body)['error']
      expect(error).to include("Name can't be blank")
      expect(error).to include("Url must be a valid HTTP or HTTPS URL")
    end
    
    it 'returns 404 for non-existent stream' do
      get '/api/v1/streams/99999', headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end