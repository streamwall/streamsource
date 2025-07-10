module Admin
  class SessionsController < Admin::BaseController
    skip_before_action :authenticate_admin!, only: [:new, :create]
    skip_before_action :check_maintenance_mode, only: [:new, :create]
    layout "admin_login"

    def new
      redirect_to admin_streams_path if current_admin_user
    end

    def create
      user = User.find_by(email: params[:email]&.downcase)

      if user&.valid_password?(params[:password]) && (user.admin? || user.editor?)
        sign_in(:user, user)
        session[:admin_user_id] = user.id
        cookies.encrypted[:user_id] = user.id
        redirect_to admin_streams_path, notice: "Successfully logged in."
      else
        flash.now[:alert] = "Invalid email or password, or insufficient privileges."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      sign_out(:user)
      session[:admin_user_id] = nil
      cookies.encrypted[:user_id] = nil
      redirect_to admin_login_path, notice: "Successfully logged out."
    end

    private

    def current_admin_user
      @current_admin_user ||= current_user if current_user&.admin?
    end
  end
end