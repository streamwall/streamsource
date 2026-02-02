require "rails_helper"

RSpec.describe Api::V1::IgnoreListsController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, role: "admin") }

  describe "GET #index" do
    before do
      request.headers.merge!(auth_headers(admin))
      create_list(:ignore_list, 3, :twitch_user)
      create_list(:ignore_list, 2, :discord_user)
      create_list(:ignore_list, 2, :url)
    end

    it "returns all ignore lists" do
      get :index
      expect(response).to have_http_status(:success)
      json = response.parsed_body
      expect(json["ignore_lists"].count).to eq(7)
    end

    it "filters by list_type" do
      get :index, params: { list_type: "twitch_user" }
      json = response.parsed_body
      expect(json["ignore_lists"].count).to eq(3)
      expect(json["ignore_lists"].all? { |il| il["list_type"] == "twitch_user" }).to be true
    end

    it "searches by value" do
      specific_list = create(:ignore_list, value: "specific-value-to-find")
      get :index, params: { search: "specific-value" }
      json = response.parsed_body
      expect(json["ignore_lists"].count).to eq(1)
      expect(json["ignore_lists"].first["id"]).to eq(specific_list.id)
    end

    it "paginates results" do
      get :index, params: { per_page: 5, page: 1 }
      json = response.parsed_body
      expect(json["ignore_lists"].count).to eq(5)
      expect(json["meta"]["total_count"]).to eq(7)
    end
  end

  describe "GET #by_type" do
    before do
      request.headers.merge!(auth_headers(admin))
      create(:ignore_list, list_type: "twitch_user", value: "baduser1")
      create(:ignore_list, list_type: "twitch_user", value: "baduser2")
      create(:ignore_list, list_type: "discord_user", value: "spammer#1234")
      create(:ignore_list, list_type: "url", value: "https://spam.com/bad")
      create(:ignore_list, list_type: "domain", value: "malware.com")
    end

    it "returns grouped ignore lists" do
      get :by_type
      expect(response).to have_http_status(:success)
      json = response.parsed_body

      expect(json).to include(
        "twitch_users" => contain_exactly("baduser1", "baduser2"),
        "discord_users" => contain_exactly("spammer#1234"),
        "urls" => contain_exactly("https://spam.com/bad"),
        "domains" => contain_exactly("malware.com"),
      )
    end
  end

  describe "GET #show" do
    let(:ignore_list) { create(:ignore_list) }

    before { request.headers.merge!(auth_headers(admin)) }

    it "returns the ignore list" do
      get :show, params: { id: ignore_list.id }
      expect(response).to have_http_status(:success)
      json = response.parsed_body
      expect(json["id"]).to eq(ignore_list.id)
    end
  end

  describe "POST #create" do
    context "when admin" do
      before { request.headers.merge!(auth_headers(admin)) }

      it "creates a new ignore list" do
        expect do
          post :create, params: {
            ignore_list: {
              list_type: "twitch_user",
              value: "newbaduser",
              notes: "Spamming in chat",
            },
          }
        end.to change(IgnoreList, :count).by(1)

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json["value"]).to eq("newbaduser")
      end

      it "returns errors for invalid data" do
        post :create, params: {
          ignore_list: {
            list_type: "invalid_type",
            value: "test",
          },
        }
        expect(response).to have_http_status(:unprocessable_content)
        json = response.parsed_body
        expect(json["errors"]).to include("List type is not included in the list")
      end
    end

    context "when regular user" do
      before { request.headers.merge!(auth_headers(user)) }

      it "returns forbidden" do
        post :create, params: {
          ignore_list: {
            list_type: "twitch_user",
            value: "test",
          },
        }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST #bulk_create" do
    let(:bulk_entries) do
      [
        { list_type: "twitch_user", value: "user1", notes: "Spam" },
        { list_type: "twitch_user", value: "user2", notes: "Harassment" },
        { list_type: "url", value: "https://bad-site.com" },
      ]
    end
    let(:bulk_params) { { entries: bulk_entries } }

    before { request.headers.merge!(auth_headers(admin)) }

    it "creates multiple ignore lists" do
      expect { post :bulk_create, params: bulk_params }.to change(IgnoreList, :count).by(3)
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["created"].count).to eq(3)
    end

    it "returns no errors for valid entries" do
      post :bulk_create, params: bulk_params
      expect(response.parsed_body["errors"]).to be_empty
    end

    it "handles partial failures" do
      create(:ignore_list, list_type: "twitch_user", value: "existing")

      post :bulk_create, params: {
        entries: [
          { list_type: "twitch_user", value: "newuser" },
          { list_type: "twitch_user", value: "existing" }, # Duplicate
          { list_type: "invalid", value: "test" }, # Invalid type
        ],
      }

      json = response.parsed_body
      expect(json["created"].count).to eq(1)
      expect(json["errors"].count).to eq(2)
    end
  end

  describe "PATCH #update" do
    let(:ignore_list) { create(:ignore_list) }

    context "when admin" do
      before { request.headers.merge!(auth_headers(admin)) }

      it "updates the ignore list" do
        patch :update, params: {
          id: ignore_list.id,
          ignore_list: {
            notes: "Updated notes",
          },
        }
        expect(response).to have_http_status(:success)
        expect(ignore_list.reload.notes).to eq("Updated notes")
      end
    end

    context "when regular user" do
      before { request.headers.merge!(auth_headers(user)) }

      it "returns forbidden" do
        patch :update, params: {
          id: ignore_list.id,
          ignore_list: { notes: "Test" },
        }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:ignore_list) { create(:ignore_list) }

    context "when admin" do
      before { request.headers.merge!(auth_headers(admin)) }

      it "deletes the ignore list" do
        expect do
          delete :destroy, params: { id: ignore_list.id }
        end.to change(IgnoreList, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context "when regular user" do
      before { request.headers.merge!(auth_headers(user)) }

      it "returns forbidden" do
        delete :destroy, params: { id: ignore_list.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE #bulk_delete" do
    let!(:lists) { create_list(:ignore_list, 5) }

    context "when admin" do
      before { request.headers.merge!(auth_headers(admin)) }

      it "deletes multiple ignore lists" do
        ids_to_delete = lists.first(3).map(&:id)

        expect do
          delete :bulk_delete, params: { ids: ids_to_delete }
        end.to change(IgnoreList, :count).by(-3)

        json = response.parsed_body
        expect(json["deleted_count"]).to eq(3)
      end
    end
  end
end
