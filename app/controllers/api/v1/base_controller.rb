module Api
  module V1
    class BaseController < ApplicationController
      include JwtAuthenticatable
      include Pundit::Authorization
      
      rescue_from Pundit::NotAuthorizedError, with: :forbidden
      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      
      # Pagination helpers
      def paginate(collection)
        page = params[:page] || ApplicationConstants::Pagination::DEFAULT_PAGE
        per_page = params[:per_page] || ApplicationConstants::Pagination::DEFAULT_PER_PAGE
        per_page = [per_page.to_i, ApplicationConstants::Pagination::MAX_PER_PAGE].min
        
        collection.page(page).per(per_page)
      end
      
      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count,
          per_page: collection.limit_value
        }
      end
      
      protected
      
      def render_success(data, status = :ok)
        render json: data, status: status
      end
      
      def render_error(message, status = :unprocessable_entity)
        render json: { error: message }, status: status
      end
      
      private
      
      def forbidden
        render_error(ApplicationConstants::Messages::FORBIDDEN, :forbidden)
      end
      
      def not_found
        render_error(ApplicationConstants::Messages::NOT_FOUND, :not_found)
      end
    end
  end
end