module Api
  module V1
    # Shared API v1 behavior.
    class BaseController < Api::BaseController
      include Pundit::Authorization

      rescue_from Pundit::NotAuthorizedError, with: :forbidden
      rescue_from ActiveRecord::RecordNotFound, with: :not_found

      # Pagination helpers
      def paginate(collection)
        page = (params[:page] || ApplicationConstants::Pagination::DEFAULT_PAGE).to_i
        per_page = (params[:per_page] || ApplicationConstants::Pagination::DEFAULT_PER_PAGE).to_i
        per_page = [per_page, ApplicationConstants::Pagination::MAX_PER_PAGE].min

        # Manual pagination using offset and limit
        offset = (page - 1) * per_page
        paginated = collection.offset(offset).limit(per_page)

        # Add singleton methods for pagination metadata
        paginated.define_singleton_method(:current_page) { page }
        paginated.define_singleton_method(:limit_value) { per_page }
        paginated.define_singleton_method(:total_count) { collection.count }
        paginated.define_singleton_method(:total_pages) { (collection.count.to_f / per_page).ceil }

        paginated
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count,
          per_page: collection.limit_value,
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

      # Helper method to provide serialization options with scope
      def serialization_scope
        SerializationScope.new(current_user)
      end

      # Simple class to pass user context to serializers
      class SerializationScope
        attr_reader :current_user

        def initialize(user)
          @current_user = user
        end
      end
    end
  end
end
