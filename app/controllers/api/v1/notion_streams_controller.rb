# frozen_string_literal: true

module Api
  module V1
    class NotionStreamsController < BaseController
      skip_before_action :authenticate_user, only: [:index]

      def index
        notion_service = NotionService.new
        notion_response = notion_service.list_active_streams

        streams = transform_notion_streams(notion_response['results'])
        
        render json: {
          data: streams,
          meta: {
            total_count: streams.count,
            has_more: notion_response['has_more'],
            next_cursor: notion_response['next_cursor']
          }
        }
      rescue StandardError => e
        render json: { error: e.message }, status: :service_unavailable
      end

      private

      def transform_notion_streams(notion_pages)
        notion_pages.map do |page|
          properties = page['properties']
          
          {
            id: page['id'],
            title: extract_title(properties['Title']),
            platform: properties['Platform']['select']&.dig('name'),
            status: properties['Status']['select']&.dig('name'),
            source: properties['Source']['url'],
            link: properties['Link']['url'],
            city: extract_text(properties['City']),
            state: properties['State']['select']&.dig('name'),
            orientation: properties['Orientation']['select']&.dig('name'),
            kind: properties['Kind']['select']&.dig('name'),
            started_at: properties['Started At']['date']&.dig('start'),
            ended_at: properties['Ended At']['date']&.dig('start'),
            is_pinned: properties['Is Pinned']['checkbox'],
            viewer_count: properties['Viewer Count']['number'],
            notes: extract_text(properties['Notes']),
            streamer: extract_relation_info(properties['Streamer']),
            created_time: page['created_time'],
            last_edited_time: page['last_edited_time']
          }
        end
      end

      def extract_title(title_property)
        title_property['title'].map { |t| t['plain_text'] }.join
      end

      def extract_text(text_property)
        return nil unless text_property['rich_text'].present?
        text_property['rich_text'].map { |t| t['plain_text'] }.join
      end

      def extract_relation_info(relation_property)
        return nil unless relation_property['relation'].present?
        
        # For now, just return the IDs
        # In a full implementation, you might want to fetch the related streamer details
        relation_property['relation'].map { |r| r['id'] }
      end
    end
  end
end