class ApplicationController < ActionController::API
  include JwtAuthenticatable
  include Pagy::Backend

  before_action :check_maintenance_mode

  private

  def check_maintenance_mode
    if Flipper.enabled?(ApplicationConstants::Features::MAINTENANCE_MODE) && !request.path.start_with?("/health")
      render json: {
        error: "The API is currently under maintenance. Please try again later.",
        maintenance: true,
      }, status: :service_unavailable
    end
  end

  def pagy_metadata(pagy)
    {
      current_page: pagy.page,
      next_page: pagy.next,
      prev_page: pagy.prev,
      total_pages: pagy.pages,
      total_count: pagy.count,
    }
  end
end
