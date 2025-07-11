module Api
  module V1
    class IgnoreListsController < BaseController
      before_action :authenticate_user!
      before_action :require_admin!
      before_action :set_ignore_list, only: [:show, :update, :destroy]

      # GET /api/v1/ignore_lists
      def index
        @ignore_lists = IgnoreList.all

        # Filter by list_type if provided
        if params[:list_type].present?
          @ignore_lists = @ignore_lists.where(list_type: params[:list_type])
        end

        # Search functionality
        if params[:search].present?
          @ignore_lists = @ignore_lists.where('value ILIKE ?', "%#{params[:search]}%")
        end

        # Pagination
        @ignore_lists = paginate(@ignore_lists)

        render json: {
          ignore_lists: @ignore_lists.as_json,
          meta: pagination_meta(@ignore_lists)
        }
      end

      # GET /api/v1/ignore_lists/by_type
      # Returns grouped ignore lists by type for easy consumption
      def by_type
        ignore_lists = IgnoreList.all

        grouped = {
          twitch_users: ignore_lists.twitch_users.pluck(:value),
          discord_users: ignore_lists.discord_users.pluck(:value),
          urls: ignore_lists.urls.pluck(:value),
          domains: ignore_lists.domains.pluck(:value)
        }

        render json: grouped
      end

      # GET /api/v1/ignore_lists/:id
      def show
        render json: @ignore_list
      end

      # POST /api/v1/ignore_lists
      def create
        @ignore_list = IgnoreList.new(ignore_list_params)

        if @ignore_list.save
          render json: @ignore_list, status: :created
        else
          render json: { errors: @ignore_list.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/ignore_lists/bulk_create
      # Allows creating multiple ignore list entries at once
      def bulk_create
        results = {
          created: [],
          errors: []
        }

        bulk_params[:entries].each do |entry|
          ignore_list = IgnoreList.new(
            list_type: entry[:list_type],
            value: entry[:value],
            notes: entry[:notes]
          )

          if ignore_list.save
            results[:created] << ignore_list
          else
            results[:errors] << {
              value: entry[:value],
              errors: ignore_list.errors.full_messages
            }
          end
        end

        render json: results, status: :created
      end

      # PATCH/PUT /api/v1/ignore_lists/:id
      def update
        if @ignore_list.update(ignore_list_params)
          render json: @ignore_list
        else
          render json: { errors: @ignore_list.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/ignore_lists/:id
      def destroy
        @ignore_list.destroy
        head :no_content
      end

      # DELETE /api/v1/ignore_lists/bulk_delete
      # Allows deleting multiple ignore list entries at once
      def bulk_delete
        ids = params[:ids] || []
        deleted_count = IgnoreList.where(id: ids).destroy_all.count

        render json: { deleted_count: deleted_count }
      end

      private

      def set_ignore_list
        @ignore_list = IgnoreList.find(params[:id])
      end

      def ignore_list_params
        params.require(:ignore_list).permit(:list_type, :value, :notes)
      end

      def bulk_params
        params.permit(entries: [:list_type, :value, :notes])
      end

      def require_admin!
        head :forbidden unless current_user.admin?
      end
    end
  end
end