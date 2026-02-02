module Admin
  class BaseController < ActionController::Base
    include Pagy::Method

    # Include helpers for session and flash
    include ActionController::Cookies
    include ActionController::RequestForgeryProtection
    include ActionController::Flash

    # Enable CSRF protection for web forms
    protect_from_forgery with: :exception

    before_action :authenticate_admin!
    before_action :check_maintenance_mode

    layout "admin"
    
    helper_method :current_user, :user_signed_in?, :current_admin_user

    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
    rescue_from ActionController::ParameterMissing, with: :parameter_missing

    private

    def authenticate_admin!
      unless user_signed_in?
        redirect_to admin_login_path, alert: "You must be logged in to access this area."
        return
      end
      
      return if current_user&.admin? || current_user&.editor?

      redirect_to admin_login_path, alert: "You must be logged in as an admin or editor to access this area."
    end

    def current_admin_user
      @current_admin_user ||= current_user if current_user&.admin?
    end
    
    def current_user
      @current_user ||= User.find_by(id: session[:admin_user_id]) if session[:admin_user_id]
    end
    
    def user_signed_in?
      current_user.present?
    end

    def check_maintenance_mode
      return unless Flipper.enabled?(ApplicationConstants::Features::MAINTENANCE_MODE)

      render "admin/shared/maintenance", layout: "admin"
    end

    def after_sign_in_path_for(_resource)
      admin_streams_path
    end

    helper_method :current_admin_user

    # Error handling
    def record_not_found(_exception)
      respond_to do |format|
        format.html do
          flash[:alert] = "The requested resource could not be found."
          redirect_to admin_streams_path
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash",
                                                    partial: "admin/shared/flash",
                                                    locals: { alert: "The requested resource could not be found." })
        end
        format.json { render json: { error: "Resource not found" }, status: :not_found }
      end
    end

    def record_invalid(exception)
      respond_to do |format|
        format.html do
          flash[:alert] = "There was an error processing your request: #{exception.message}"
          redirect_back(fallback_location: admin_streams_path)
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash",
                                                    partial: "admin/shared/flash",
                                                    locals: { alert: "There was an error processing your request." })
        end
        format.json { render json: { error: exception.message }, status: :unprocessable_entity }
      end
    end

    def parameter_missing(exception)
      respond_to do |format|
        format.html do
          flash[:alert] = "Required parameter missing: #{exception.param}"
          redirect_back(fallback_location: admin_streams_path)
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash",
                                                    partial: "admin/shared/flash",
                                                    locals: { alert: "Required information is missing." })
        end
        format.json { render json: { error: "Parameter missing: #{exception.param}" }, status: :bad_request }
      end
    end
  end
end
