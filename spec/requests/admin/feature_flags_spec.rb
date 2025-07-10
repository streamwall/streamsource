require "rails_helper"

RSpec.describe "Admin::FeatureFlags", type: :request do
  let(:admin_user) { create(:user, :admin) }

  before do
    # Allow real Flipper calls for these tests
    allow(Flipper).to receive(:enabled?).and_call_original
    allow(Flipper).to receive(:enable).and_call_original
    allow(Flipper).to receive(:disable).and_call_original
    allow(Flipper).to receive(:add).and_call_original
    
    # Reset all feature flags to a known state
    ApplicationConstants::Features.constants.each do |const|
      feature_name = ApplicationConstants::Features.const_get(const)
      Flipper.disable(feature_name)
    end
  end

  describe "GET /admin/feature_flags" do
    before { setup_admin_auth(admin_user) }

    it "returns successful response" do
      get admin_feature_flags_path
      expect(response).to have_http_status(:success)
    end

    it "displays all feature flags" do
      get admin_feature_flags_path

      # Check that all defined features are displayed
      ApplicationConstants::Features.constants.each do |const|
        feature_name = ApplicationConstants::Features.const_get(const)
        expect(response.body).to include(feature_name.to_s)
      end
    end

    it "shows correct enabled/disabled status" do
      # Enable one feature
      Flipper.enable(ApplicationConstants::Features::STREAM_ANALYTICS)

      get admin_feature_flags_path

      expect(response.body).to include("Enabled")
      expect(response.body).to include("Disabled")
    end
  end

  describe "PATCH /admin/feature_flags/:id" do
    before { setup_admin_auth(admin_user) }

    let(:feature_flag) { ApplicationConstants::Features::STREAM_ANALYTICS }

    context "enabling a feature" do
      it "enables the feature flag" do
        expect(Flipper.enabled?(feature_flag)).to be false

        patch admin_feature_flag_path(feature_flag), params: { action_type: "enable" }

        expect(Flipper.enabled?(feature_flag)).to be true
      end

      it "redirects with success message" do
        patch admin_feature_flag_path(feature_flag), params: { action_type: "enable" }

        expect(response).to redirect_to(admin_feature_flags_path)
        expect(flash[:notice]).to eq("Feature '#{feature_flag}' has been enabled.")
      end
    end

    context "disabling a feature" do
      before { Flipper.enable(feature_flag) }

      it "disables the feature flag" do
        expect(Flipper.enabled?(feature_flag)).to be true

        patch admin_feature_flag_path(feature_flag), params: { action_type: "disable" }

        expect(Flipper.enabled?(feature_flag)).to be false
      end

      it "redirects with success message" do
        patch admin_feature_flag_path(feature_flag), params: { action_type: "disable" }

        expect(response).to redirect_to(admin_feature_flags_path)
        expect(flash[:notice]).to eq("Feature '#{feature_flag}' has been disabled.")
      end
    end

    context "with invalid action" do
      it "redirects with error message" do
        patch admin_feature_flag_path(feature_flag), params: { action_type: "invalid" }

        expect(response).to redirect_to(admin_feature_flags_path)
        expect(flash[:alert]).to eq("Invalid action.")
      end

      it "does not change feature state" do
        initial_state = Flipper.enabled?(feature_flag)

        patch admin_feature_flag_path(feature_flag), params: { action_type: "invalid" }

        expect(Flipper.enabled?(feature_flag)).to eq(initial_state)
      end
    end

    context "when Flipper raises an error" do
      before do
        allow(Flipper).to receive(:enable).and_raise(StandardError, "Flipper error")
      end

      it "handles the error gracefully" do
        patch admin_feature_flag_path(feature_flag), params: { action_type: "enable" }

        expect(response).to redirect_to(admin_feature_flags_path)
        expect(flash[:alert]).to include("Error updating feature flag: Flipper error")
      end
    end
  end

  describe "authorization" do
    context "when not logged in" do
      it "redirects to login" do
        # Clear any session
        allow_any_instance_of(Admin::BaseController).to receive(:current_admin_user).and_return(nil)

        get admin_feature_flags_path
        expect(response).to redirect_to(admin_login_path)
      end
    end

    context "when logged in as non-admin" do
      let(:editor_user) { create(:user, :editor) }

      it "redirects to login" do
        # Mock current_admin_user to return a non-admin user
        allow_any_instance_of(Admin::BaseController).to receive(:current_admin_user).and_return(editor_user)

        get admin_feature_flags_path
        expect(response).to redirect_to(admin_login_path)
      end
    end
  end

  describe "feature flag descriptions" do
    before { setup_admin_auth(admin_user) }

    it "displays appropriate descriptions for each feature" do
      get admin_feature_flags_path

      # Check that feature flags are displayed - looking at humanized constant names
      expect(response.body).to include("Stream analytics") # STREAM_ANALYTICS.humanize
      expect(response.body).to include("Stream export") # STREAM_EXPORT.humanize
      expect(response.body).to include("Maintenance mode") # MAINTENANCE_MODE.humanize
    end
  end
end
