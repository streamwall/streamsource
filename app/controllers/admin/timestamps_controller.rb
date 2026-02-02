module Admin
  # CRUD for timestamps in the admin UI.
  class TimestampsController < BaseController
    before_action :set_timestamp, only: %i[show edit update destroy]

    def index
      @pagy, @timestamps = pagy(
        Timestamp.includes(:user, :streams, :timestamp_streams)
                  .filtered(filter_params)
                  .recent,
        items: 20,
      )

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def show
      @timestamp_streams = @timestamp.timestamp_streams.includes(:stream, :added_by_user)

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def new
      @timestamp = Timestamp.new(event_timestamp: Time.current)

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def edit
      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def create
      @timestamp = Timestamp.new(timestamp_params)
      @timestamp.user = current_admin_user

      respond_to do |format|
        if @timestamp.save
          notice = t("admin.timestamps.created")
          format.html { redirect_to admin_timestamps_path, notice: notice }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.prepend("timestamps", partial: "admin/timestamps/timestamp",
                                                 locals: { timestamp: @timestamp }),
              turbo_stream.replace("flash", partial: "admin/shared/flash",
                                            locals: { notice: notice }),
              turbo_stream.replace("new_timestamp_modal", ""),
            ]
          end
        else
          format.html { render :new, status: :unprocessable_content }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "timestamp_form",
              partial: "admin/timestamps/form",
              locals: { timestamp: @timestamp },
            )
          end
        end
      end
    end

    def update
      respond_to do |format|
        if @timestamp.update(timestamp_params)
          notice = t("admin.timestamps.updated")
          format.html { redirect_to admin_timestamp_path(@timestamp), notice: notice }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(@timestamp, partial: "admin/timestamps/timestamp",
                                               locals: { timestamp: @timestamp }),
              turbo_stream.replace("flash", partial: "admin/shared/flash",
                                            locals: { notice: notice }),
              turbo_stream.replace("edit_timestamp_#{@timestamp.id}_modal", ""),
            ]
          end
        else
          format.html { render :edit, status: :unprocessable_content }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "timestamp_form",
              partial: "admin/timestamps/form",
              locals: { timestamp: @timestamp },
            )
          end
        end
      end
    end

    def destroy
      @timestamp.destroy!

      respond_to do |format|
        notice = t("admin.timestamps.deleted")
        format.html { redirect_to admin_timestamps_path, notice: notice }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(@timestamp),
            turbo_stream.replace("flash", partial: "admin/shared/flash",
                                          locals: { notice: notice }),
          ]
        end
      end
    end

    # Add a stream to a timestamp
    def add_stream
      @timestamp = Timestamp.find(params[:id])
      @stream = Stream.find(params[:stream_id])

      @timestamp.add_stream!(
        @stream,
        current_admin_user,
        timestamp_seconds: params[:timestamp_seconds],
      )

      respond_to do |format|
        notice = t("admin.timestamps.stream_added")
        format.html { redirect_to admin_timestamp_path(@timestamp), notice: notice }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("timestamp_streams",
                                 partial: "admin/timestamps/timestamp_stream",
                                 locals: { timestamp_stream: @timestamp.timestamp_streams.find_by(stream: @stream) }),
            turbo_stream.replace("flash", partial: "admin/shared/flash",
                                          locals: { notice: notice }),
          ]
        end
      end
    end

    private

    def set_timestamp
      @timestamp = Timestamp.find(params[:id])
    end

    def timestamp_params
      params.expect(timestamp: %i[title description event_timestamp])
    end

    def filter_params
      params.permit(:search, :start_date, :end_date)
    end
  end
end
