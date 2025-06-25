module Admin
  class SessionsController < ActionController::Base
    protect_from_forgery with: :exception
    layout 'admin_login'
    
    def new
      redirect_to admin_streams_path if current_admin_user
    end
    
    def create
      user = User.find_by(email: params[:email]&.downcase)
      
      if user&.authenticate(params[:password]) && user.admin?
        session[:admin_user_id] = user.id
        cookies.encrypted[:user_id] = user.id
        redirect_to admin_streams_path, notice: 'Successfully logged in.'
      else
        flash.now[:alert] = 'Invalid email or password, or insufficient privileges.'
        render :new, status: :unprocessable_entity
      end
    end
    
    def destroy
      session[:admin_user_id] = nil
      cookies.encrypted[:user_id] = nil
      redirect_to admin_login_path, notice: 'Successfully logged out.'
    end
    
    private
    
    def current_admin_user
      @current_admin_user ||= User.find_by(id: session[:admin_user_id]) if session[:admin_user_id]
    end
  end
end