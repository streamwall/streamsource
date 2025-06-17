module Admin
  class BaseController < ActionController::Base
    include JwtAuthenticatable
    include Pagy::Backend
    
    # Include helpers for session and flash
    include ActionController::Cookies
    include ActionController::RequestForgeryProtection
    include ActionController::Flash
    
    # Enable CSRF protection for web forms
    protect_from_forgery with: :exception
    
    # Skip JWT auth for session-based auth
    skip_before_action :authenticate_user!
    
    before_action :authenticate_admin!
    before_action :check_maintenance_mode
    
    layout 'admin'
    
    private
    
    def authenticate_admin!
      unless current_admin_user&.admin?
        redirect_to admin_login_path, alert: 'You must be logged in as an admin to access this area.'
      end
    end
    
    def current_admin_user
      @current_admin_user ||= User.find_by(id: session[:admin_user_id]) if session[:admin_user_id]
    end
    
    def check_maintenance_mode
      if Flipper.enabled?(ApplicationConstants::Features::MAINTENANCE_MODE)
        render 'admin/shared/maintenance', layout: 'admin'
      end
    end
    
    def after_sign_in_path_for(resource)
      admin_streams_path
    end
    
    helper_method :current_admin_user
  end
end