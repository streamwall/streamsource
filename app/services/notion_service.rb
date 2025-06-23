# frozen_string_literal: true

class NotionService
  include HTTParty
  base_uri 'https://api.notion.com/v1'

  def initialize
    @headers = {
      'Authorization' => "Bearer #{ENV['NOTION_API_KEY']}",
      'Content-Type' => 'application/json',
      'Notion-Version' => '2022-06-28'
    }
  end

  # Query active streams from Notion database
  def list_active_streams(database_id: ENV['NOTION_STREAMS_DB_ID'])
    response = self.class.post(
      "/databases/#{database_id}/query",
      headers: @headers,
      body: {
        filter: {
          property: 'Status',
          select: { equals: 'active' }
        },
        sorts: [
          {
            property: 'Started At',
            direction: 'descending'
          }
        ]
      }.to_json
    )

    handle_response(response)
  end

  # Create a new stream in Notion
  def create_stream(stream_data)
    response = self.class.post(
      '/pages',
      headers: @headers,
      body: {
        parent: { database_id: ENV['NOTION_STREAMS_DB_ID'] },
        properties: build_stream_properties(stream_data)
      }.to_json
    )

    handle_response(response)
  end

  # Update an existing stream in Notion
  def update_stream(page_id, updates)
    response = self.class.patch(
      "/pages/#{page_id}",
      headers: @headers,
      body: {
        properties: build_stream_properties(updates)
      }.to_json
    )

    handle_response(response)
  end

  # Get a single stream by ID
  def get_stream(page_id)
    response = self.class.get(
      "/pages/#{page_id}",
      headers: @headers
    )

    handle_response(response)
  end

  # Query streamers from Notion database
  def list_streamers(database_id: ENV['NOTION_STREAMERS_DB_ID'])
    response = self.class.post(
      "/databases/#{database_id}/query",
      headers: @headers,
      body: {
        sorts: [
          {
            property: 'Name',
            direction: 'ascending'
          }
        ]
      }.to_json
    )

    handle_response(response)
  end

  private

  def build_stream_properties(data)
    properties = {}

    properties['Title'] = { title: [{ text: { content: data[:title] } }] } if data[:title]
    properties['Platform'] = { select: { name: data[:platform] } } if data[:platform]
    properties['Status'] = { select: { name: data[:status] } } if data[:status]
    properties['Source'] = { url: data[:source] } if data[:source]
    properties['Link'] = { url: data[:link] } if data[:link]
    properties['City'] = { rich_text: [{ text: { content: data[:city] } }] } if data[:city]
    properties['State'] = { select: { name: data[:state] } } if data[:state]
    properties['Orientation'] = { select: { name: data[:orientation] } } if data[:orientation]
    properties['Kind'] = { select: { name: data[:kind] } } if data[:kind]
    properties['Started At'] = { date: { start: data[:started_at]&.iso8601 } } if data[:started_at]
    properties['Ended At'] = { date: { start: data[:ended_at]&.iso8601 } } if data[:ended_at]
    properties['Is Pinned'] = { checkbox: data[:is_pinned] } if data.key?(:is_pinned)
    properties['Viewer Count'] = { number: data[:viewer_count] } if data[:viewer_count]
    properties['Notes'] = { rich_text: [{ text: { content: data[:notes] } }] } if data[:notes]

    # Handle streamer relation if provided
    if data[:streamer_id]
      properties['Streamer'] = { relation: [{ id: data[:streamer_id] }] }
    end

    properties
  end

  def handle_response(response)
    if response.success?
      response.parsed_response
    else
      Rails.logger.error "Notion API Error: #{response.code} - #{response.body}"
      raise "Notion API Error: #{response.code} - #{response.message}"
    end
  end
end