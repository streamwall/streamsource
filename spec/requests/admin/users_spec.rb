require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:admin_user) { create(:user, :admin) }

  before do
    allow_any_instance_of(Admin::BaseController).to receive(:current_admin_user).and_return(admin_user)
    allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
  end

  describe "GET /admin/users" do
    let!(:users) { create_list(:user, 3) }

    it "returns successful response" do
      get admin_users_path
      expect(response).to have_http_status(:success)
    end

    it "displays users" do
      get admin_users_path
      users.each do |user|
        expect(response.body).to include(user.email)
      end
    end
  end

  describe "GET /admin/users/:id" do
    let(:user) { create(:user) }

    it "returns successful response" do
      get admin_user_path(user)
      expect(response).to have_http_status(:success)
    end

    it "displays user details" do
      get admin_user_path(user)
      expect(response.body).to include(user.email)
    end
  end

  describe "GET /admin/users/new" do
    it "returns successful response" do
      get admin_new_user_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/users" do
    let(:valid_params) do
      {
        user: {
          email: "newuser@example.com",
          password: "Password123!",
          role: "default",
        },
      }
    end

    context "with valid params" do
      it "creates user" do
        expect do
          post admin_users_path, params: valid_params
        end.to change(User, :count).by(1)
      end

      it "redirects to users index" do
        post admin_users_path, params: valid_params
        expect(response).to redirect_to(admin_users_path)
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        { user: { email: "invalid", password: "short" } }
      end

      it "does not create user" do
        expect do
          post admin_users_path, params: invalid_params
        end.not_to change(User, :count)
      end

      it "returns unprocessable entity" do
        post admin_users_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/users/:id/edit" do
    let(:user) { create(:user) }

    it "returns successful response" do
      get admin_edit_user_path(user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/users/:id" do
    let(:user) { create(:user) }
    let(:update_params) do
      {
        user: {
          email: "updated@example.com",
          role: "editor",
        },
      }
    end

    context "with valid params" do
      it "updates user" do
        patch admin_user_path(user), params: update_params
        user.reload
        expect(user.email).to eq("updated@example.com")
        expect(user.role).to eq("editor")
      end

      it "redirects to user show page" do
        patch admin_user_path(user), params: update_params
        expect(response).to redirect_to(admin_user_path(user))
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        { user: { email: "invalid" } }
      end

      it "does not update user" do
        original_email = user.email
        patch admin_user_path(user), params: invalid_params
        user.reload
        expect(user.email).to eq(original_email)
      end
    end
  end

  describe "PATCH /admin/users/:id/toggle_admin" do
    let(:user) { create(:user, role: "default") }

    it "toggles admin status" do
      expect do
        patch admin_toggle_admin_user_path(user)
      end.to change { user.reload.role }.from("default").to("admin")
    end

    it "redirects to users index" do
      patch admin_toggle_admin_user_path(user)
      expect(response).to redirect_to(admin_users_path)
    end

    context "when user is admin" do
      let(:user) { create(:user, :admin) }

      it "changes to default" do
        expect do
          patch admin_toggle_admin_user_path(user)
        end.to change { user.reload.role }.from("admin").to("default")
      end
    end
  end

  describe "DELETE /admin/users/:id" do
    let!(:user) { create(:user) }

    it "deletes user" do
      expect do
        delete admin_user_path(user)
      end.to change(User, :count).by(-1)
    end

    it "redirects to index" do
      delete admin_user_path(user)
      expect(response).to redirect_to(admin_users_path)
    end

    context "when trying to delete self" do
      it "does not delete user" do
        expect do
          delete admin_user_path(admin_user)
        end.not_to change(User, :count)
      end

      it "redirects with alert" do
        delete admin_user_path(admin_user)
        expect(response).to redirect_to(admin_users_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
