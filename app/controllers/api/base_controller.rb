module Api
  class BaseController < ActionController::API
    include JwtAuthenticatable
    include Pagy::Method

    before_action :check_maintenance_mode

    private

    def check_maintenance_mode
      return if request.path.start_with?("/health")
      return unless Flipper.enabled?(ApplicationConstants::Features::MAINTENANCE_MODE)

      render json: {
        error: "The API is currently under maintenance. Please try again later.",
        maintenance: true,
      }, status: :service_unavailable
    end

    def pagy_metadata(pagy)
      {
        current_page: pagy.page,
        next_page: pagy.next,
        prev_page: pagy.previous,
        total_pages: pagy.pages,
        total_count: pagy.count,
      }
    end
  end
end
