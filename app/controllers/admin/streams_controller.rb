module Admin
  # CRUD for streams in the admin UI.
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

      respond_to do |format|
        return render_stream_form(format, :new) unless location_valid?

        if @stream.save
          render_create_success(format)
        else
          render_stream_form(format, :new)
        end
      end
    end

    def update
      respond_to do |format|
        return render_stream_form(format, :edit) unless location_valid?

        if @stream.update(stream_params)
          render_update_success(format)
        else
          render_stream_form(format, :edit)
        end
      end
    end

    def destroy
      @stream.destroy!

      respond_to do |format|
        notice = t("admin.streams.deleted")
        format.html { redirect_to admin_streams_path, notice: notice }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(@stream),
            turbo_stream.replace("flash", partial: "admin/shared/flash",
                                          locals: { notice: notice }),
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

    def render_create_success(format)
      notice = t("admin.streams.created")
      format.html { redirect_to admin_streams_path, notice: notice }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.prepend("streams", partial: "admin/streams/stream", locals: { stream: @stream }),
          turbo_stream.replace("flash", partial: "admin/shared/flash", locals: { notice: notice }),
          turbo_stream.replace("modal", ""),
        ]
      end
    end

    def render_update_success(format)
      notice = t("admin.streams.updated")
      format.html { redirect_to admin_streams_path, notice: notice }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(@stream, partial: "admin/streams/stream", locals: { stream: @stream }),
          turbo_stream.replace("flash", partial: "admin/shared/flash", locals: { notice: notice }),
          turbo_stream.replace("modal", ""),
        ]
      end
    end

    def render_stream_form(format, template)
      load_users
      format.html { render template, status: :unprocessable_content }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "stream_form",
          partial: "admin/streams/form",
          locals: { stream: @stream, users: @users },
        )
      end
    end

    def location_valid?
      return true unless location_validation_enabled?

      city = params.dig(:stream, :city)
      return true if city.blank?

      location = Location.find_or_create_from_params(
        city: city,
        state_province: params.dig(:stream, :state),
      )

      return true if location.present?

      @stream.errors.add(:city, t("admin.streams.invalid_city"))
      false
    end

    def location_validation_enabled?
      Flipper.enabled?(ApplicationConstants::Features::LOCATION_VALIDATION)
    end

    def load_users
      @users = User.order(:email)
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
