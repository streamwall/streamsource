module Api
  module V1
    class StreamsController < BaseController
      before_action :set_stream, only: [:show, :update, :destroy, :pin, :unpin]
      
      def index
        streams = policy_scope(Stream)
        
        # Apply filters
        streams = streams.where(status: params[:status]) if params[:status].present?
        streams = streams.where.not(status: params[:notStatus]) if params[:notStatus].present?
        streams = streams.by_user(User.find(params[:user_id])) if params[:user_id].present?
        
        # Apply sorting
        case params[:sort]
        when 'name'
          streams = streams.order(name: :asc)
        when '-name'
          streams = streams.order(name: :desc)
        when 'created'
          streams = streams.order(created_at: :asc)
        when '-created'
          streams = streams.order(created_at: :desc)
        else
          streams = streams.recent
        end
        
        # Pagination
        streams = paginate(streams)
        
        render json: {
          streams: ActiveModelSerializers::SerializableResource.new(
            streams,
            each_serializer: StreamSerializer
          ),
          meta: pagination_meta(streams)
        }
      end
      
      def show
        render json: @stream, serializer: StreamSerializer
      end
      
      def create
        stream = current_user.streams.build(stream_params)
        authorize stream
        
        if stream.save
          render json: stream, serializer: StreamSerializer, status: :created
        else
          render_error(stream.errors.full_messages.join(', '), :unprocessable_entity)
        end
      end
      
      def update
        authorize @stream
        
        if @stream.update(stream_params)
          render json: @stream, serializer: StreamSerializer
        else
          render_error(@stream.errors.full_messages.join(', '), :unprocessable_entity)
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
        render json: @stream, serializer: StreamSerializer
      end
      
      def unpin
        authorize @stream, :update?
        @stream.unpin!
        render json: @stream, serializer: StreamSerializer
      end
      
      # Analytics endpoint (feature flagged)
      def analytics
        unless Flipper.enabled?(ApplicationConstants::Features::STREAM_ANALYTICS, current_user)
          render_error('This feature is not currently available', :forbidden)
          return
        end
        
        set_stream
        authorize @stream, :show?
        
        # Placeholder analytics data
        analytics_data = {
          stream_id: @stream.id,
          views_count: rand(1000..10000),
          unique_viewers: rand(100..1000),
          average_watch_time: rand(60..3600),
          peak_concurrent_viewers: rand(50..500),
          last_updated: Time.current
        }
        
        render json: analytics_data
      end
      
      # Bulk import endpoint (feature flagged)
      def bulk_import
        unless Flipper.enabled?(ApplicationConstants::Features::STREAM_BULK_IMPORT, current_user)
          render_error('Bulk import is not currently available', :forbidden)
          return
        end
        
        authorize Stream, :create?
        
        streams_data = params[:streams] || []
        imported_count = 0
        errors = []
        
        streams_data.each_with_index do |stream_params, index|
          stream = current_user.streams.build(stream_params.permit(:name, :url, :status))
          if stream.save
            imported_count += 1
          else
            errors << { index: index, errors: stream.errors.full_messages }
          end
        end
        
        render json: {
          imported: imported_count,
          total: streams_data.length,
          errors: errors
        }
      end
      
      # Export endpoint (feature flagged)  
      def export
        unless Flipper.enabled?(ApplicationConstants::Features::STREAM_EXPORT, current_user)
          render_error('Export feature is not currently available', :forbidden)
          return
        end
        
        streams = policy_scope(Stream)
        
        # Apply same filters as index
        streams = streams.where(status: params[:status]) if params[:status].present?
        streams = streams.where.not(status: params[:notStatus]) if params[:notStatus].present?
        
        export_data = streams.map do |stream|
          {
            name: stream.name,
            url: stream.url,
            status: stream.status,
            is_pinned: stream.is_pinned,
            created_at: stream.created_at.iso8601,
            owner_email: stream.user.email
          }
        end
        
        render json: {
          exported_at: Time.current.iso8601,
          count: export_data.length,
          streams: export_data
        }
      end
      
      private
      
      def set_stream
        @stream = Stream.find(params[:id])
      end
      
      def stream_params
        params.permit(:url, :name, :status)
      end
    end
  end
end