module Admin
  # CRUD for streams in the admin UI.
  # rubocop:disable Metrics/ClassLength
  class StreamsController < BaseController
    STREAM_TABLE_COLUMNS = [
      { key: "streamer", label: "Streamer", sortable: true },
      { key: "title", label: "Title", sortable: true },
      { key: "source", label: "Source", sortable: true },
      { key: "link", label: "Link", sortable: true },
      { key: "platform", label: "Platform", sortable: true },
      { key: "status", label: "Status", sortable: true },
      { key: "city", label: "City", sortable: true },
      { key: "state", label: "State", sortable: true },
      { key: "kind", label: "Kind", sortable: true },
      { key: "orientation", label: "Orientation", sortable: true },
      { key: "started_at", label: "Started At", sortable: true },
      { key: "last_checked_at", label: "Last Checked", sortable: true },
      { key: "last_live_at", label: "Last Live", sortable: true },
      { key: "actions", label: "Actions", sortable: false },
    ].freeze

    helper_method :stream_table_columns

    before_action :set_stream, only: %i[show edit update destroy toggle_pin]

    def index
      @stream_table_preferences = stream_table_preferences
      @hidden_columns = sanitize_hidden_columns(@stream_table_preferences["hidden_columns"])
      @column_order = sanitize_column_order(@stream_table_preferences["column_order"])
      @sort_column = resolved_sort_column(@stream_table_preferences)
      @sort_direction = resolved_sort_direction(@stream_table_preferences)

      persist_sort_preferences if persist_sort_preferences?

      @pagy, @streams = pagy(
        Stream.includes(:streamer)
              .filtered(filter_params)
              .sorted(@sort_column, @sort_direction),
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
          row_partial = "admin/streams/stream"
          if params[:context] == "spreadsheet"
            preferences = stream_table_preferences
            @hidden_columns = sanitize_hidden_columns(preferences["hidden_columns"])
            row_partial = "admin/streams/spreadsheet_row"
          end

          render turbo_stream: turbo_stream.replace(
            @stream,
            partial: row_partial,
            locals: { stream: @stream },
          )
        end
      end
    end

    def update_preferences
      return head :unauthorized unless current_user
      return head :bad_request unless params.key?(:hidden_columns) || params.key?(:column_order)

      preferences = stream_table_preferences
      preferences["hidden_columns"] = sanitize_hidden_columns(params[:hidden_columns]) if params.key?(:hidden_columns)
      preferences["column_order"] = sanitize_column_order(params[:column_order]) if params.key?(:column_order)
      current_user.update!(stream_table_preferences: preferences)

      head :ok
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
        row_partial = "admin/streams/stream"
        if params[:context] == "spreadsheet"
          preferences = stream_table_preferences
          @hidden_columns = sanitize_hidden_columns(preferences["hidden_columns"])
          row_partial = "admin/streams/spreadsheet_row"
        end

        render turbo_stream: [
          turbo_stream.replace(@stream, partial: row_partial, locals: { stream: @stream }),
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

    def stream_table_columns
      STREAM_TABLE_COLUMNS
    end

    def stream_table_column_keys
      @stream_table_column_keys ||= STREAM_TABLE_COLUMNS.pluck(:key)
    end

    def stream_table_preferences
      return {} unless current_user

      (current_user.stream_table_preferences || {}).deep_dup
    end

    def sanitize_hidden_columns(columns)
      Array(columns).map(&:to_s) & stream_table_column_keys
    end

    def sanitize_column_order(columns)
      ordered = Array(columns).map(&:to_s) & stream_table_column_keys
      missing = stream_table_column_keys - ordered
      ordered + missing
    end

    def resolved_sort_column(preferences)
      candidate = params[:sort].presence
      return candidate if candidate.present? && Stream::SORTABLE_COLUMNS.include?(candidate.to_s)

      stored = preferences.dig("sort", "column")
      stored if Stream::SORTABLE_COLUMNS.include?(stored.to_s)
    end

    def resolved_sort_direction(preferences)
      candidate = params[:direction].presence
      return "asc" if candidate == "asc"
      return "desc" if candidate == "desc"

      stored = preferences.dig("sort", "direction")
      stored == "asc" ? "asc" : "desc"
    end

    def persist_sort_preferences?
      params[:sort].present? && @sort_column.present? && current_user.present?
    end

    def persist_sort_preferences
      preferences = @stream_table_preferences
      preferences["sort"] = { "column" => @sort_column, "direction" => @sort_direction }
      current_user.update!(stream_table_preferences: preferences)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
