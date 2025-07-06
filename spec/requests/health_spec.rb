require 'rails_helper'

RSpec.describe "Health Checks", type: :request do
  describe "GET /health" do
    it "returns ok status" do
      get "/health"
      
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({ "status" => "ok" })
    end
    
    it "does not require authentication" do
      get "/health"
      expect(response).to have_http_status(:ok)
    end
    
    it "responds quickly" do
      start_time = Time.current
      get "/health"
      end_time = Time.current
      
      expect(end_time - start_time).to be < 0.1 # Should respond in under 100ms
    end
  end
  
  describe "GET /health/live" do
    it "returns 200 for liveness probe" do
      get "/health/live"
      
      expect(response).to have_http_status(:ok)
      expect(response.body).to be_empty
    end
    
    it "does not require authentication" do
      get "/health/live"
      expect(response).to have_http_status(:ok)
    end
  end
  
  describe "GET /health/ready" do
    context "when all services are ready" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
        allow(Redis.current).to receive(:ping).and_return("PONG")
      end
      
      it "returns 200 when database and redis are available" do
        get "/health/ready"
        
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_empty
      end
    end
    
    context "when database is not ready" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(false)
      end
      
      it "returns 503 when database is unavailable" do
        get "/health/ready"
        
        expect(response).to have_http_status(:service_unavailable)
      end
    end
    
    context "when redis is not ready" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
        allow(Redis.current).to receive(:ping).and_raise(Redis::ConnectionError)
      end
      
      it "returns 503 when redis is unavailable" do
        get "/health/ready"
        
        expect(response).to have_http_status(:service_unavailable)
      end
    end
    
    it "does not require authentication" do
      get "/health/ready"
      expect(response).not_to have_http_status(:unauthorized)
    end
  end
  
  describe "metrics endpoint" do
    it "returns prometheus metrics" do
      get "/metrics"
      
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/plain")
      expect(response.body).to include("# TYPE")
      expect(response.body).to include("# HELP")
    end
    
    it "includes rails metrics" do
      get "/metrics"
      
      expect(response.body).to include("rails_")
    end
    
    it "does not require authentication" do
      get "/metrics"
      expect(response).to have_http_status(:ok)
    end
  end
  
  describe "error handling" do
    it "handles database connection errors gracefully" do
      allow(ActiveRecord::Base.connection).to receive(:active?).and_raise(StandardError)
      
      get "/health/ready"
      
      expect(response).to have_http_status(:service_unavailable)
    end
    
    it "handles redis connection errors gracefully" do
      allow(Redis.current).to receive(:ping).and_raise(StandardError)
      
      get "/health/ready"
      
      expect(response).to have_http_status(:service_unavailable)
    end
  end
  
  describe "performance" do
    it "health check does not query database" do
      expect(ActiveRecord::Base.connection).not_to receive(:execute)
      
      get "/health"
    end
    
    it "readiness check performs minimal queries" do
      query_count = 0
      
      ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
        query_count += 1
      end
      
      get "/health/ready"
      
      ActiveSupport::Notifications.unsubscribe('sql.active_record')
      
      expect(query_count).to be <= 1
    end
  end
end