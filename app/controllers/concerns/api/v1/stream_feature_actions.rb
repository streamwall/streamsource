module Api
  module V1
    # Feature-flagged stream actions (analytics/import/export).
    module StreamFeatureActions
      extend ActiveSupport::Concern

      def analytics
        unless feature_enabled?(ApplicationConstants::Features::STREAM_ANALYTICS)
          render_feature_unavailable("This feature is not currently available")
          return
        end

        set_stream
        authorize @stream, :show?

        render json: analytics_payload(@stream)
      end

      def bulk_import
        unless feature_enabled?(ApplicationConstants::Features::STREAM_BULK_IMPORT)
          render_feature_unavailable("Bulk import is not currently available")
          return
        end

        authorize Stream, :create?

        streams_data = params[:streams] || []
        result = import_streams(streams_data)

        render json: {
          imported: result[:imported],
          total: streams_data.length,
          errors: result[:errors],
        }
      end

      def export
        unless feature_enabled?(ApplicationConstants::Features::STREAM_EXPORT)
          render_feature_unavailable("Export feature is not currently available")
          return
        end

        streams = export_scope
        render json: export_payload(streams)
      end

      private

      def feature_enabled?(feature)
        Flipper.enabled?(feature, current_user)
      end

      def render_feature_unavailable(message)
        render_error(message, :forbidden)
      end

      def analytics_payload(stream)
        {
          stream_id: stream.id,
          views_count: rand(1000..10_000),
          unique_viewers: rand(100..1000),
          average_watch_time: rand(60..3600),
          peak_concurrent_viewers: rand(50..500),
          last_updated: Time.current,
        }
      end

      def import_streams(streams_data)
        imported_count = 0
        errors = []

        streams_data.each_with_index do |stream_params, index|
          stream = current_user.streams.build(stream_params.permit(:source, :link, :status, :platform,
                                                                   :orientation, :kind, :city, :state,
                                                                   :notes, :title, :posted_by))
          if stream.save
            imported_count += 1
          else
            errors << { index: index, errors: stream.errors.full_messages }
          end
        end

        { imported: imported_count, errors: errors }
      end

      def export_scope
        scope = policy_scope(Stream)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where.not(status: params[:notStatus]) if params[:notStatus].present?
        scope
      end

      def export_payload(streams)
        export_data = streams.map { |stream| export_stream_attributes(stream) }

        {
          exported_at: Time.current.iso8601,
          count: export_data.length,
          streams: export_data,
        }
      end

      def export_stream_attributes(stream)
        {
          source: stream.source,
          link: stream.link,
          status: stream.status,
          platform: stream.platform,
          orientation: stream.orientation,
          kind: stream.kind,
          city: stream.city,
          state: stream.state,
          notes: stream.notes,
          title: stream.title,
          posted_by: stream.posted_by,
          is_pinned: stream.is_pinned,
          created_at: stream.created_at.iso8601,
          last_checked_at: stream.last_checked_at&.iso8601,
          last_live_at: stream.last_live_at&.iso8601,
          owner_email: stream.user.email,
        }
      end
    end
  end
end
