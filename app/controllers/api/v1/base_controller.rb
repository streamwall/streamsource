module Api
  module V1
    class BaseController < ApplicationController
      include JwtAuthenticatable
      
      # Pagination helpers
      def paginate(collection)
        page = params[:page] || 1
        per_page = params[:per_page] || 20
        
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
    end
  end
end