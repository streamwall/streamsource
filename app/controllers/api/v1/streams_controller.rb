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