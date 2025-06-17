require 'rails_helper'

RSpec.describe 'Authentication Flow', type: :request do
  describe 'complete authentication workflow' do
    it 'allows user to sign up, login, and access protected resources' do
      # Step 1: Sign up
      post '/api/v1/users/signup', params: {
        email: 'newuser@example.com',
        password: 'ValidPass123',
        role: 'editor'
      }
      
      expect(response).to have_http_status(:created)
      signup_response = JSON.parse(response.body)
      expect(signup_response['user']['email']).to eq('newuser@example.com')
      expect(signup_response['token']).to be_present
      
      # Step 2: Use token to create a stream
      post '/api/v1/streams',
        params: { source: 'My Stream', link: 'https://example.com/stream' },
        headers: { 'Authorization' => "Bearer #{signup_response['token']}" }
      
      expect(response).to have_http_status(:created)
      stream_id = JSON.parse(response.body)['id']
      
      # Step 3: Login again
      post '/api/v1/users/login', params: {
        email: 'newuser@example.com',
        password: 'ValidPass123'
      }
      
      expect(response).to have_http_status(:success)
      login_response = JSON.parse(response.body)
      new_token = login_response['token']
      
      # Step 4: Access protected resource with new token
      get '/api/v1/streams',
        headers: { 'Authorization' => "Bearer #{new_token}" }
      
      expect(response).to have_http_status(:success)
      streams = JSON.parse(response.body)['streams']
      expect(streams.any? { |s| s['id'] == stream_id }).to be true
    end
    
    it 'prevents access without authentication' do
      get '/api/v1/streams'
      expect(response).to have_http_status(:unauthorized)
      
      post '/api/v1/streams', params: { source: 'Test', link: 'https://test.com' }
      expect(response).to have_http_status(:unauthorized)
      
      delete '/api/v1/streams/1'
      expect(response).to have_http_status(:unauthorized)
    end
    
    it 'handles invalid login attempts' do
      create(:user, email: 'existing@example.com', password: 'Password123!')
      
      # Wrong password
      post '/api/v1/users/login', params: {
        email: 'existing@example.com',
        password: 'wrongpassword'
      }
      
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)['error']).to eq('Invalid email or password')
      
      # Non-existent user
      post '/api/v1/users/login', params: {
        email: 'nonexistent@example.com',
        password: 'anypassword'
      }
      
      expect(response).to have_http_status(:unauthorized)
    end
  end
  
  describe 'token expiration' do
    let(:user) { create(:user) }
    
    it 'rejects expired tokens' do
      # Create an expired token
      payload = {
        user_id: user.id,
        email: user.email,
        role: user.role,
        exp: 1.hour.ago.to_i
      }
      expired_token = JWT.encode(payload, Rails.application.secret_key_base)
      
      get '/api/v1/streams',
        headers: { 'Authorization' => "Bearer #{expired_token}" }
      
      expect(response).to have_http_status(:unauthorized)
    end
  end
  
  describe 'concurrent sessions' do
    let(:user) { create(:user, :editor) }
    
    it 'allows multiple valid tokens for the same user' do
      # First login
      post '/api/v1/users/login', params: {
        email: user.email,
        password: 'Password123!'
      }
      token1 = JSON.parse(response.body)['token']
      
      # Second login
      post '/api/v1/users/login', params: {
        email: user.email,
        password: 'Password123!'
      }
      token2 = JSON.parse(response.body)['token']
      
      # Both tokens should work
      get '/api/v1/streams',
        headers: { 'Authorization' => "Bearer #{token1}" }
      expect(response).to have_http_status(:success)
      
      get '/api/v1/streams',
        headers: { 'Authorization' => "Bearer #{token2}" }
      expect(response).to have_http_status(:success)
    end
  end
end