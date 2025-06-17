require 'rails_helper'

RSpec.describe Api::V1::StreamsController, type: :controller do
  let(:user) { create(:user) }
  let(:editor) { create(:user, :editor) }
  let(:admin) { create(:user, :admin) }
  let(:stream) { create(:stream, user: editor) }
  
  describe 'GET #index' do
    let!(:active_streams) { create_list(:stream, 3, user: editor, status: 'active') }
    let!(:inactive_stream) { create(:stream, user: editor, status: 'inactive') }
    let!(:pinned_stream) { create(:stream, user: editor, is_pinned: true) }
    
    context 'without authentication' do
      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
    
    context 'with authentication' do
      before { request.headers.merge!(auth_headers(user)) }
      
      it 'returns success' do
        get :index
        expect(response).to have_http_status(:success)
      end
      
      it 'returns all streams' do
        get :index
        json = JSON.parse(response.body)
        
        expect(json['streams'].length).to eq(5)
      end
      
      it 'filters by status' do
        get :index, params: { status: 'active' }
        json = JSON.parse(response.body)
        
        expect(json['streams'].length).to eq(4)
        expect(json['streams'].all? { |s| s['status'] == 'active' }).to be true
      end
      
      it 'filters by notStatus' do
        get :index, params: { notStatus: 'inactive' }
        json = JSON.parse(response.body)
        
        expect(json['streams'].length).to eq(4)
        expect(json['streams'].none? { |s| s['status'] == 'inactive' }).to be true
      end
      
      it 'filters by user_id' do
        other_user = create(:user)
        create(:stream, user: other_user)
        
        get :index, params: { user_id: editor.id }
        json = JSON.parse(response.body)
        
        expect(json['streams'].length).to eq(5)
        expect(json['streams'].all? { |s| s['user']['id'] == editor.id }).to be true
      end
      
      it 'filters by is_pinned' do
        get :index, params: { is_pinned: true }
        json = JSON.parse(response.body)
        
        expect(json['streams'].length).to eq(1)
        expect(json['streams'][0]['is_pinned']).to be true
      end
      
      it 'orders by pinned first' do
        get :index
        json = JSON.parse(response.body)
        
        expect(json['streams'][0]['is_pinned']).to be true
      end
      
      it 'paginates results' do
        get :index, params: { per_page: 2, page: 1 }
        json = JSON.parse(response.body)
        
        expect(json['streams'].length).to eq(2)
        expect(json['meta']['current_page']).to eq(1)
        expect(json['meta']['total_pages']).to eq(3)
      end
    end
  end
  
  describe 'GET #show' do
    context 'without authentication' do
      it 'returns unauthorized' do
        get :show, params: { id: stream.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
    
    context 'with authentication' do
      before { request.headers.merge!(auth_headers(user)) }
      
      it 'returns the stream' do
        get :show, params: { id: stream.id }
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(stream.id)
      end
      
      it 'returns 404 for non-existent stream' do
        get :show, params: { id: 99999 }
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end
  
  describe 'POST #create' do
    let(:valid_params) do
      {
        name: 'New Stream',
        url: 'https://example.com/new-stream'
      }
    end
    
    context 'as default user' do
      before { request.headers.merge!(auth_headers(user)) }
      
      it 'returns forbidden' do
        post :create, params: valid_params
        expect(response).to have_http_status(:forbidden)
      end
    end
    
    context 'as editor' do
      before { request.headers.merge!(auth_headers(editor)) }
      
      it 'creates a stream' do
        expect {
          post :create, params: valid_params
        }.to change(Stream, :count).by(1)
      end
      
      it 'returns created stream' do
        post :create, params: valid_params
        
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['name']).to eq('New Stream')
        expect(json['user']['id']).to eq(editor.id)
      end
      
      it 'handles invalid params' do
        post :create, params: { name: '', url: 'invalid' }
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to include("Name can't be blank")
        expect(json['error']).to include("Url must be a valid HTTP or HTTPS URL")
      end
    end
  end
  
  describe 'PATCH #update' do
    let(:update_params) do
      {
        id: stream.id,
        name: 'Updated Name',
        status: 'inactive'
      }
    end
    
    context 'as stream owner' do
      before { request.headers.merge!(auth_headers(editor)) }
      
      it 'updates the stream' do
        patch :update, params: update_params
        
        expect(response).to have_http_status(:success)
        stream.reload
        expect(stream.name).to eq('Updated Name')
        expect(stream.status).to eq('inactive')
      end
    end
    
    context 'as non-owner editor' do
      let(:other_editor) { create(:user, :editor) }
      before { request.headers.merge!(auth_headers(other_editor)) }
      
      it 'returns forbidden' do
        patch :update, params: update_params
        expect(response).to have_http_status(:forbidden)
      end
    end
    
    context 'as admin' do
      before { request.headers.merge!(auth_headers(admin)) }
      
      it 'updates any stream' do
        patch :update, params: update_params
        expect(response).to have_http_status(:success)
      end
    end
  end
  
  describe 'DELETE #destroy' do
    context 'as stream owner' do
      before { request.headers.merge!(auth_headers(editor)) }
      
      it 'deletes the stream' do
        stream # create it first
        expect {
          delete :destroy, params: { id: stream.id }
        }.to change(Stream, :count).by(-1)
      end
      
      it 'returns no content' do
        delete :destroy, params: { id: stream.id }
        expect(response).to have_http_status(:no_content)
      end
    end
    
    context 'as non-owner' do
      before { request.headers.merge!(auth_headers(user)) }
      
      it 'returns forbidden' do
        delete :destroy, params: { id: stream.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
  
  describe 'PUT #pin' do
    before { request.headers.merge!(auth_headers(editor)) }
    
    it 'pins the stream' do
      put :pin, params: { id: stream.id }
      
      expect(response).to have_http_status(:success)
      expect(stream.reload.is_pinned).to be true
    end
    
    it 'returns updated stream' do
      put :pin, params: { id: stream.id }
      
      json = JSON.parse(response.body)
      expect(json['is_pinned']).to be true
    end
  end
  
  describe 'DELETE #unpin' do
    let(:pinned_stream) { create(:stream, user: editor, is_pinned: true) }
    
    before { request.headers.merge!(auth_headers(editor)) }
    
    it 'unpins the stream' do
      delete :unpin, params: { id: pinned_stream.id }
      
      expect(response).to have_http_status(:success)
      expect(pinned_stream.reload.is_pinned).to be false
    end
  end
end