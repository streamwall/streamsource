module Admin
  class StreamsController < BaseController
    before_action :set_stream, only: %i[show edit update destroy toggle_pin]

    def index
      @pagy, @streams = pagy(
        Stream.includes(:streamer)
              .filtered(filter_params)
              .ordered,
        items: 20,
      )

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def show
      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def new
      @stream = Stream.new
      @users = User.order(:email)

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def edit
      @users = User.order(:email)

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def create
      @stream = Stream.new(stream_params)

      # Handle location validation if feature is enabled
      if Flipper.enabled?(ApplicationConstants::Features::LOCATION_VALIDATION)
        if params[:stream][:city].present?
          location_result = Location.find_or_create_from_params(
            city: params[:stream][:city],
            state_province: params[:stream][:state]
          )
          
          if location_result.respond_to?(:errors) && !location_result.valid?
            @stream.errors.add(:city, location_result.errors[:city].first)
            
            respond_to do |format|
              @users = User.order(:email)
              format.html { render :new, status: :unprocessable_entity }
              format.turbo_stream do
                render turbo_stream: turbo_stream.replace(
                  "stream_form",
                  partial: "admin/streams/form",
                  locals: { stream: @stream, users: @users },
                )
              end
            end
            return
          end
        end
      end

      respond_to do |format|
        if @stream.save
          format.html { redirect_to admin_streams_path, notice: "Stream was successfully created." }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.prepend("streams", partial: "admin/streams/stream", locals: { stream: @stream }),
              turbo_stream.replace("flash", partial: "admin/shared/flash",
                                            locals: { notice: "Stream was successfully created." }),
              turbo_stream.replace("modal", ""),
            ]
          end
        else
          @users = User.order(:email)
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "stream_form",
              partial: "admin/streams/form",
              locals: { stream: @stream, users: @users },
            )
          end
        end
      end
    end

    def update
      # Handle location validation if feature is enabled
      if Flipper.enabled?(ApplicationConstants::Features::LOCATION_VALIDATION)
        if params[:stream][:city].present?
          location_result = Location.find_or_create_from_params(
            city: params[:stream][:city],
            state_province: params[:stream][:state]
          )
          
          if location_result.respond_to?(:errors) && !location_result.valid?
            @stream.errors.add(:city, location_result.errors[:city].first)
            
            respond_to do |format|
              @users = User.order(:email)
              format.html { render :edit, status: :unprocessable_entity }
              format.turbo_stream do
                render turbo_stream: turbo_stream.replace(
                  "stream_form",
                  partial: "admin/streams/form",
                  locals: { stream: @stream, users: @users },
                )
              end
            end
            return
          end
        end
      end

      respond_to do |format|
        if @stream.update(stream_params)
          format.html { redirect_to admin_streams_path, notice: "Stream was successfully updated." }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(@stream, partial: "admin/streams/stream", locals: { stream: @stream }),
              turbo_stream.replace("flash", partial: "admin/shared/flash",
                                            locals: { notice: "Stream was successfully updated." }),
              turbo_stream.replace("modal", ""),
            ]
          end
        else
          @users = User.order(:email)
          format.html { render :edit, status: :unprocessable_entity }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "stream_form",
              partial: "admin/streams/form",
              locals: { stream: @stream, users: @users },
            )
          end
        end
      end
    end

    def destroy
      @stream.destroy!

      respond_to do |format|
        format.html { redirect_to admin_streams_path, notice: "Stream was successfully deleted." }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(@stream),
            turbo_stream.replace("flash", partial: "admin/shared/flash",
                                          locals: { notice: "Stream was successfully deleted." }),
          ]
        end
      end
    end

    def toggle_pin
      @stream.toggle_pin!

      respond_to do |format|
        format.html { redirect_to admin_streams_path }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            @stream,
            partial: "admin/streams/stream",
            locals: { stream: @stream },
          )
        end
      end
    end

    private

    def set_stream
      @stream = Stream.find(params[:id])
    end

    def stream_params
      params.expect(stream: %i[source link status platform orientation
                               kind city state notes title
                               posted_by user_id streamer_id is_pinned])
    end

    def filter_params
      params.permit(:status, :platform, :kind, :orientation, :user_id, :search, :is_pinned, :is_archived)
    end
  end
end
