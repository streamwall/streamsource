module Admin
  # CRUD for users in the admin UI.
  class UsersController < BaseController
    before_action :set_user, only: %i[show edit update destroy toggle_admin]

    def index
      @pagy, @users = pagy(
        User.includes(:streams, :streamers)
            .order(:email),
      )
    end

    def show; end

    def new
      @user = User.new
    end

    def edit; end

    def create
      @user = User.new(user_params)

      if @user.save
        redirect_to admin_users_path, notice: t("admin.users.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @user.update(update_user_params)
        redirect_to admin_user_path(@user), notice: t("admin.users.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @user == current_admin_user
        redirect_to admin_users_path, alert: t("admin.users.cannot_delete_self")
      else
        @user.destroy
        redirect_to admin_users_path, notice: t("admin.users.deleted")
      end
    end

    def toggle_admin
      if @user.admin?
        @user.update(role: "default")
      else
        @user.update(role: "admin")
      end

      redirect_to admin_users_path, notice: t("admin.users.role_updated")
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.expect(user: %i[email password password_confirmation role])
    end

    def update_user_params
      permitted = params.expect(user: %i[email password password_confirmation role])
      # Remove password fields if they are blank
      if permitted[:password].blank?
        permitted.delete(:password)
        permitted.delete(:password_confirmation)
      end
      permitted
    end
  end
end
