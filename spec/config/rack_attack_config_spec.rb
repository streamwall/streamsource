require 'rails_helper'

RSpec.describe 'Rack::Attack configuration' do
  describe 'throttle rules' do
    it 'configures req/ip throttle' do
      throttle = Rack::Attack.throttles['req/ip']
      expect(throttle).not_to be_nil
      expect(throttle.limit).to eq(ApplicationConstants::RateLimit::REQUESTS_PER_MINUTE)
      expect(throttle.period).to eq(60) # 1.minute in seconds
    end
    
    it 'configures logins/ip throttle' do
      throttle = Rack::Attack.throttles['logins/ip']
      expect(throttle).not_to be_nil
      expect(throttle.limit).to eq(ApplicationConstants::RateLimit::LOGIN_ATTEMPTS_PER_PERIOD)
      expect(throttle.period).to eq(ApplicationConstants::RateLimit::LOGIN_PERIOD)
    end
    
    it 'configures logins/email throttle' do
      throttle = Rack::Attack.throttles['logins/email']
      expect(throttle).not_to be_nil
      expect(throttle.limit).to eq(ApplicationConstants::RateLimit::LOGIN_ATTEMPTS_PER_PERIOD)
      expect(throttle.period).to eq(ApplicationConstants::RateLimit::LOGIN_PERIOD)
    end
    
    it 'configures signups/ip throttle' do
      throttle = Rack::Attack.throttles['signups/ip']
      expect(throttle).not_to be_nil
      expect(throttle.limit).to eq(ApplicationConstants::RateLimit::SIGNUP_ATTEMPTS_PER_PERIOD)
      expect(throttle.period).to eq(ApplicationConstants::RateLimit::SIGNUP_PERIOD)
    end
    
    it 'configures exponential backoff levels' do
      ApplicationConstants::RateLimit::BACKOFF_LEVELS.each do |level|
        throttle = Rack::Attack.throttles["req/ip/#{level}"]
        expect(throttle).not_to be_nil
        expect(throttle.limit).to eq(50 * level)
        expect(throttle.period).to eq((ApplicationConstants::RateLimit::BACKOFF_BASE**level).seconds)
      end
    end
  end
  
  describe 'safelist rules' do
    it 'configures localhost safelist' do
      safelist = Rack::Attack.safelists['allow-localhost']
      expect(safelist).not_to be_nil
    end
  end
  
  describe 'throttled response' do
    it 'returns JSON error message' do
      expect(Rack::Attack.throttled_responder).not_to be_nil
    end
  end
  
  describe 'cache configuration' do
    it 'has a cache store configured' do
      expect(Rack::Attack.cache.store).not_to be_nil
    end
  end
end