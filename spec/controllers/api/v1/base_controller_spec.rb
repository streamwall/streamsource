require "rails_helper"

RSpec.describe Api::V1::BaseController, type: :controller do
  let(:user) { create(:user) }

  controller do
    def index
      render_success({ message: "success" })
    end

    def error_action
      render_error("Test error", :bad_request)
    end

    def paginated_action
      records = User.all
      paginated_records = paginate(records)
      render json: {
        data: paginated_records,
        meta: pagination_meta(paginated_records),
      }
    end
  end

  before do
    routes.draw do
      get "index" => "api/v1/base#index"
      get "error_action" => "api/v1/base#error_action"
      get "paginated_action" => "api/v1/base#paginated_action"
    end
  end

  describe "#render_success" do
    context "with authentication" do
      before do
        request.headers.merge!(auth_headers(user))
        get :index
      end

      it "returns success response" do
        expect(response).to have_http_status(:success)
      end

      it "returns data in correct format" do
        json = response.parsed_body
        expect(json["message"]).to eq("success")
      end
    end

    context "without authentication" do
      before { get :index }

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "#render_error" do
    before do
      request.headers.merge!(auth_headers(user))
      get :error_action
    end

    it "returns error status" do
      expect(response).to have_http_status(:bad_request)
    end

    it "returns error message" do
      json = response.parsed_body
      expect(json["error"]).to eq("Test error")
    end
  end

  describe "#paginate" do
    let!(:users) { create_list(:user, 30) }

    before do
      request.headers.merge!(auth_headers(user))
    end

    it "paginates results" do
      get :paginated_action, params: { page: 1, per_page: 10 }
      json = response.parsed_body

      expect(json["data"].length).to eq(10)
    end

    it "includes pagination metadata" do
      get :paginated_action, params: { page: 2, per_page: 10 }
      json = response.parsed_body

      expect(json["meta"]["current_page"]).to eq(2)
      expect(json["meta"]["per_page"]).to eq(10)
      expect(json["meta"]["total_pages"]).to eq(4) # 31 users total (30 + the auth user)
      expect(json["meta"]["total_count"]).to eq(31)
    end

    it "respects per_page limits" do
      get :paginated_action, params: { per_page: 200 }
      json = response.parsed_body

      expect(json["data"].length).to eq(31) # Should not exceed actual count
      expect(json["meta"]["per_page"]).to eq(100) # Max is 100
    end
  end

  describe "Pundit integration" do
    controller do
      def pundit_action
        authorize User.new
        render json: { authorized: true }
      end
    end

    before do
      routes.draw { get "pundit_action" => "api/v1/base#pundit_action" }
    end

    it "handles Pundit NotAuthorizedError" do
      request.headers.merge!(auth_headers(user))
      allow_any_instance_of(described_class).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)

      get :pundit_action

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to eq("You are not authorized to perform this action")
    end
  end
end
