module Api
  module V1
    # API endpoints for stream resources.
    class StreamsController < BaseController
      include StreamFeatureActions

      before_action :set_stream, only: %i[show update destroy pin unpin]

      def index
        streams = policy_scope(Stream)
        streams = sorted_streams(filtered_streams(streams))
        streams = paginate(streams)

        render json: {
          streams: ActiveModelSerializers::SerializableResource.new(
            streams,
            each_serializer: StreamSerializer,
            scope: serialization_scope,
            adapter: :attributes,
          ).as_json,
          meta: pagination_meta(streams),
        }
      end

      def show
        render json: @stream, serializer: StreamSerializer, scope: serialization_scope
      end

      def create
        stream = current_user.streams.build(stream_params.except(:location))
        authorize stream

        return unless assign_location?(stream)

        if stream.save
          render json: stream, serializer: StreamSerializer, scope: serialization_scope, status: :created
        else
          render_error(stream.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      def update
        authorize @stream

        return unless apply_location_update?(@stream)

        if @stream.update(stream_params.except(:location))
          render json: @stream, serializer: StreamSerializer, scope: serialization_scope
        else
          render_error(@stream.errors.full_messages.join(", "), :unprocessable_entity)
        end
      end

      def destroy
        authorize @stream
        @stream.destroy!
        head :no_content
      end

      def pin
        authorize @stream, :update?
        @stream.pin!
        render json: @stream, serializer: StreamSerializer, scope: serialization_scope
      end

      def unpin
        authorize @stream, :update?
        @stream.unpin!
        render json: @stream, serializer: StreamSerializer, scope: serialization_scope
      end

      private

      def set_stream
        @stream = Stream.find(params[:id])
      end

      def stream_params
        params.permit(:source, :link, :status, :platform, :orientation, :kind,
                      :city, :state, :notes, :title, :posted_by, :location_id)
      end

      def filtered_streams(scope)
        filters = {
          status: ->(relation, value) { relation.where(status: value) },
          user_id: ->(relation, value) { relation.by_user(User.find(value)) },
          is_pinned: ->(relation, value) { relation.where(is_pinned: value) },
        }

        scoped = filters.reduce(scope) do |relation, (param_key, handler)|
          value = params[param_key]
          value.present? ? handler.call(relation, value) : relation
        end

        value = params[:notStatus]
        value.present? ? scoped.where.not(status: value) : scoped
      end

      def sorted_streams(scope)
        case params[:sort]
        when "name"
          scope.order(source: :asc)
        when "-name"
          scope.order(source: :desc)
        when "created"
          scope.order(created_at: :asc)
        when "-created"
          scope.order(created_at: :desc)
        else
          scope.order(is_pinned: :desc).recent
        end
      end

      def assign_location?(stream)
        return true if location_params.blank?

        location_result = Location.find_or_create_from_params(location_params)
        if location_result.nil?
          render_error("Location validation failed", :unprocessable_entity)
          return false
        end

        if location_result.respond_to?(:errors) && location_result.errors.any?
          render_error(location_error_message(location_result), :unprocessable_entity)
          return false
        end

        stream.location = location_result
        true
      end

      def apply_location_update?(stream)
        return assign_location?(stream) if location_params.present?

        stream.location = nil if params.key?(:location) && params[:location].nil?
        true
      end

      def location_error_message(location_result)
        "Location validation failed: #{location_result.errors.full_messages.join(', ')}"
      end

      def location_params
        return nil unless params[:location].is_a?(Hash)

        params.expect(location: %i[city state_province region country latitude longitude])
      end
    end
  end
end
