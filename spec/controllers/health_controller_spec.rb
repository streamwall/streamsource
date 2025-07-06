require "rails_helper"

RSpec.describe HealthController, type: :controller do
  describe "GET #index" do
    before { get :index }

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "returns JSON response" do
      expect(response.content_type).to match(%r{application/json})
    end

    it "returns health status" do
      json = response.parsed_body
      expect(json["status"]).to eq("healthy")
      expect(json["timestamp"]).to be_present
      expect(json["version"]).to eq("1.0.0")
    end

    it "does not require authentication" do
      # Test passes without any auth headers
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #live" do
    before { get :live }

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "returns simple OK status" do
      json = response.parsed_body
      expect(json["status"]).to eq("ok")
    end
  end

  describe "GET #ready" do
    context "when database is connected" do
      before { get :ready }

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns ready status" do
        json = response.parsed_body
        expect(json["status"]).to eq("ready")
        expect(json["database"]).to eq("connected")
      end
    end

    context "when database is not connected" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(PG::ConnectionBad, "connection error")
        get :ready
      end

      it "returns service unavailable" do
        expect(response).to have_http_status(:service_unavailable)
      end

      it "returns error details" do
        json = response.parsed_body
        expect(json["status"]).to eq("not ready")
        expect(json["error"]).to include("connection error")
      end
    end

    context "with other database errors" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(StandardError, "unknown error")
        get :ready
      end

      it "returns service unavailable" do
        expect(response).to have_http_status(:service_unavailable)
      end

      it "returns generic error" do
        json = response.parsed_body
        expect(json["status"]).to eq("not ready")
        expect(json["error"]).to eq("unknown error")
      end
    end
  end
end
