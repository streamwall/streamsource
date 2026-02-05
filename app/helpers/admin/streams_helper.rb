module Admin
  # Helpers for admin streams views.
  # rubocop:disable Metrics/ModuleLength
  module StreamsHelper
    def stream_sort_link(label, column, current_sort:, current_direction:)
      return label unless Stream::SORTABLE_COLUMNS.include?(column)

      direction = stream_sort_next_direction(column, current_sort, current_direction)
      link_to admin_streams_path(stream_sort_params(column, direction)),
              data: {
                action: "stream-table-preferences#rememberScroll",
                turbo_frame: "streams_list",
                turbo_action: "advance",
              },
              class: "inline-flex items-center gap-1 text-gray-500 hover:text-gray-700" do
        safe_join([tag.span(label), stream_sort_icon(column, current_sort, current_direction)])
      end
    end

    def stream_sort_aria(column, current_sort, current_direction)
      return "none" unless column == current_sort

      current_direction == "asc" ? "ascending" : "descending"
    end

    def stream_column_class(column, base_class, hidden_columns)
      classes = [base_class]
      classes << "hidden" if hidden_columns.include?(column)
      classes.join(" ")
    end

    def streamer_options
      @streamer_options ||= Streamer.includes(:streamer_accounts).order(:name).map do |streamer|
        platforms = streamer.streamer_accounts.select(&:is_active).map(&:platform).uniq
        label = streamer.name
        label += " (#{platforms.join(', ')})" if platforms.any?
        [label, streamer.id]
      end
    end

    def streamer_label_for(streamer_id)
      return nil if streamer_id.blank?

      streamer_options.each_with_object({}) do |(label, id), memo|
        memo[id] = label
      end[streamer_id]
    end

    private

    def stream_sort_params(column, direction)
      params
        .except(:page)
        .permit(
          :status,
          :platform,
          :kind,
          :orientation,
          :user_id,
          :search,
          :is_pinned,
          :is_archived,
          :sort,
          :direction,
        )
        .to_h
        .merge(sort: column, direction: direction)
    end

    def stream_sort_next_direction(column, current_sort, current_direction)
      return "asc" unless column == current_sort

      current_direction == "asc" ? "desc" : "asc"
    end

    def stream_sort_icon(column, current_sort, current_direction)
      active = column == current_sort
      if active && current_direction == "asc"
        stream_sort_icon_up
      elsif active
        stream_sort_icon_down
      else
        stream_sort_icon_neutral
      end
    end

    def stream_sort_icon_up
      tag.svg(
        xmlns: "http://www.w3.org/2000/svg",
        fill: "none",
        viewBox: "0 0 24 24",
        stroke: "currentColor",
        class: "h-3 w-3 text-gray-700",
      ) do
        tag.path(
          stroke_linecap: "round",
          stroke_linejoin: "round",
          stroke_width: "2",
          d: "M5 15l7-7 7 7",
        )
      end
    end

    def stream_sort_icon_down
      tag.svg(
        xmlns: "http://www.w3.org/2000/svg",
        fill: "none",
        viewBox: "0 0 24 24",
        stroke: "currentColor",
        class: "h-3 w-3 text-gray-700",
      ) do
        tag.path(
          stroke_linecap: "round",
          stroke_linejoin: "round",
          stroke_width: "2",
          d: "M19 9l-7 7-7-7",
        )
      end
    end

    def stream_sort_icon_neutral
      tag.svg(
        xmlns: "http://www.w3.org/2000/svg",
        fill: "none",
        viewBox: "0 0 24 24",
        stroke: "currentColor",
        class: "h-3 w-3 text-gray-400",
      ) do
        tag.path(
          stroke_linecap: "round",
          stroke_linejoin: "round",
          stroke_width: "2",
          d: "M7 11l5-5 5 5M7 13l5 5 5-5",
        )
      end
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
