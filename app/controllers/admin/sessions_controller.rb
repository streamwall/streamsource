module Admin
  # Admin login/logout flow.
  class SessionsController < Admin::BaseController
    skip_before_action :authenticate_admin!, only: %i[new create]
    skip_before_action :check_maintenance_mode, only: %i[new create]
    layout "admin_login"

    def new
      redirect_to admin_streams_path if current_admin_user
    end

    def create
      user = authenticate_admin_user

      if user
        sign_in_admin(user)
        redirect_to admin_streams_path, notice: t("admin.sessions.login_success")
      else
        render_login_failed
      end
    end

    def destroy
      sign_out(:user)
      session[:admin_user_id] = nil
      cookies.encrypted[:user_id] = nil
      redirect_to admin_login_path, notice: t("admin.sessions.logout_success")
    end

    private

    def authenticate_admin_user
      user = User.find_by(email: params[:email]&.downcase)
      return user if user&.valid_password?(params[:password]) && (user.admin? || user.editor?)

      nil
    end

    def sign_in_admin(user)
      sign_in(:user, user)
      session[:admin_user_id] = user.id
      cookies.encrypted[:user_id] = user.id
    end

    def render_login_failed
      flash.now[:alert] = t("admin.sessions.login_failed")
      render :new, status: :unprocessable_content
    end

    def current_admin_user
      @current_admin_user ||= current_user if current_user&.admin?
    end
  end
end
