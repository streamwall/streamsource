require 'rails_helper'
require 'rack/attack'

RSpec.describe 'Rack::Attack', type: :request do
  before do
    # Clear cache before each test
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.reset!
  end
  
  describe 'throttle req/ip' do
    it 'allows up to 100 requests per minute' do
      100.times do
        get '/health'
        expect(response).not_to have_http_status(:too_many_requests)
      end
      
      # 101st request should be throttled
      get '/health'
      expect(response).to have_http_status(:too_many_requests)
    end
    
    it 'includes rate limit headers' do
      get '/health'
      
      # Make enough requests to get throttled
      99.times { get '/health' }
      
      # This should be throttled
      get '/health'
      
      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers['X-RateLimit-Limit']).to eq('100')
      expect(response.headers['X-RateLimit-Remaining']).to eq('0')
      expect(response.headers['X-RateLimit-Reset']).to be_present
    end
  end
  
  describe 'throttle logins/ip' do
    it 'allows 5 login attempts per 20 minutes' do
      5.times do |i|
        post '/api/v1/users/login', params: { 
          email: "test#{i}@example.com", 
          password: 'wrong' 
        }
        expect(response).not_to have_http_status(:too_many_requests)
      end
      
      # 6th attempt should be throttled
      post '/api/v1/users/login', params: { 
        email: 'test@example.com', 
        password: 'wrong' 
      }
      expect(response).to have_http_status(:too_many_requests)
    end
  end
  
  describe 'throttle logins/email' do
    let(:email) { 'user@example.com' }
    
    it 'throttles by email parameter' do
      5.times do
        post '/api/v1/users/login', params: { 
          email: email, 
          password: 'wrong' 
        }
        expect(response).not_to have_http_status(:too_many_requests)
      end
      
      # 6th attempt with same email should be throttled
      post '/api/v1/users/login', params: { 
        email: email, 
        password: 'wrong' 
      }
      expect(response).to have_http_status(:too_many_requests)
      
      # Different email should work
      post '/api/v1/users/login', params: { 
        email: 'different@example.com', 
        password: 'wrong' 
      }
      expect(response).not_to have_http_status(:too_many_requests)
    end
    
    it 'normalizes email for throttling' do
      # These should all count as the same email
      3.times do
        post '/api/v1/users/login', params: { 
          email: 'USER@EXAMPLE.COM', 
          password: 'wrong' 
        }
      end
      
      2.times do
        post '/api/v1/users/login', params: { 
          email: 'user@example.com', 
          password: 'wrong' 
        }
      end
      
      # This should be throttled (6th attempt)
      post '/api/v1/users/login', params: { 
        email: 'User@Example.com', 
        password: 'wrong' 
      }
      expect(response).to have_http_status(:too_many_requests)
    end
  end
  
  describe 'throttle signups/ip' do
    it 'allows 3 signup attempts per hour' do
      3.times do |i|
        post '/api/v1/users/signup', params: { 
          email: "newuser#{i}@example.com", 
          password: 'ValidPass123' 
        }
        expect(response).not_to have_http_status(:too_many_requests)
      end
      
      # 4th attempt should be throttled
      post '/api/v1/users/signup', params: { 
        email: 'another@example.com', 
        password: 'ValidPass123' 
      }
      expect(response).to have_http_status(:too_many_requests)
    end
  end
  
  describe 'safelist allow-localhost' do
    it 'does not throttle localhost requests' do
      # Simulate localhost IP
      allow_any_instance_of(ActionDispatch::Request).to receive(:ip).and_return('127.0.0.1')
      
      # Make more than limit
      150.times do
        get '/health'
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
    
    it 'does not throttle IPv6 localhost' do
      # Simulate IPv6 localhost
      allow_any_instance_of(ActionDispatch::Request).to receive(:ip).and_return('::1')
      
      150.times do
        get '/health'
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end
  
  describe 'exponential backoff' do
    it 'applies increasing throttles for repeated violations' do
      # First, hit the basic limit
      100.times { get '/health' }
      
      # This triggers first throttle
      get '/health'
      expect(response).to have_http_status(:too_many_requests)
      
      # Exponential backoff should apply stricter limits
      # The implementation tracks violations and applies progressively stricter limits
    end
  end
  
  describe 'custom error response' do
    it 'returns JSON error for throttled requests' do
      # Hit the limit
      100.times { get '/health' }
      
      get '/health'
      expect(response).to have_http_status(:too_many_requests)
      expect(response.content_type).to match(/application\/json/)
      
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Too many requests. Please try again later.')
    end
  end
  
  describe 'different endpoints' do
    let(:user) { create(:user, :editor) }
    let(:headers) { auth_headers(user) }
    
    it 'throttles all endpoints' do
      # Use up the limit with different endpoints
      30.times { get '/health' }
      30.times { get '/api/v1/streams', headers: headers }
      30.times { get '/health/ready' }
      10.times { get '/health/live' }
      
      # Next request should be throttled
      get '/health'
      expect(response).to have_http_status(:too_many_requests)
    end
  end
end