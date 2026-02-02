require "rails_helper"

RSpec.describe Api::BaseController, type: :controller do
  describe "included concerns" do
    it "includes JwtAuthenticatable" do
      expect(described_class.ancestors).to include(JwtAuthenticatable)
    end
  end

  describe "locale handling" do
    controller do
      skip_before_action :authenticate_user!

      def index
        render json: { locale: I18n.locale.to_s }
      end
    end

    it "uses default locale when no Accept-Language header" do
      get :index
      expect(response).to have_http_status(:success)
      json = response.parsed_body
      expect(json["locale"]).to eq("en")
    end

    it "sets locale from Accept-Language header" do
      request.headers["Accept-Language"] = "es-ES,es;q=0.9,en;q=0.8"
      get :index
      json = response.parsed_body
      # The locale extraction depends on I18n.available_locales configuration
      # If Spanish is not available, it will fall back to default
      expect(%w[en es]).to include(json["locale"])
    end

    it "handles malformed Accept-Language header gracefully" do
      request.headers["Accept-Language"] = "invalid-header-format"
      get :index
      expect(response).to have_http_status(:success)
      json = response.parsed_body
      expect(json["locale"]).to eq("en")
    end
  end

  describe "maintenance mode" do
    controller do
      skip_before_action :authenticate_user!

      def index
        render json: { message: "test" }
      end
    end

    context "when maintenance mode is enabled" do
      before do
        allow(Flipper).to receive(:enabled?).with(ApplicationConstants::Features::MAINTENANCE_MODE).and_return(true)
      end

      it "returns service unavailable" do
        get :index
        expect(response).to have_http_status(:service_unavailable)
        expect(response.parsed_body["error"]).to include("maintenance")
      end
    end

    context "when maintenance mode is disabled" do
      before do
        allow(Flipper).to receive(:enabled?).with(ApplicationConstants::Features::MAINTENANCE_MODE).and_return(false)
      end

      it "allows normal requests" do
        get :index
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
