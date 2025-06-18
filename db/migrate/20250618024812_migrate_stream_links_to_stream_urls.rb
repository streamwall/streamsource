class MigrateStreamLinksToStreamUrls < ActiveRecord::Migration[8.0]
  def up
    # Skip if no streams exist
    return unless defined?(Stream) && Stream.table_exists? && Stream.count > 0
    
    Stream.find_each do |stream|
      next unless stream.link.present?
      
      # Create or find existing StreamUrl for this streamer and URL
      stream_url = if stream.streamer.present?
        stream.streamer.stream_urls.find_or_create_by(
          url: stream.link,
          platform: stream.platform
        ) do |su|
          su.url_type = 'stream'
          su.platform = stream.platform
          su.title = stream.title
          su.notes = stream.notes
          su.is_active = !stream.is_archived?
          su.created_by = stream.user
          su.last_checked_at = stream.last_checked_at
        end
      else
        # If no streamer, create a default one or skip
        # For now, we'll skip streams without streamers
        Rails.logger.warn "Skipping stream #{stream.id} - no streamer associated"
        next
      end
      
      # Associate the stream with the stream_url
      stream.update_column(:stream_url_id, stream_url.id)
    end
    
    puts "Migrated #{Stream.where.not(stream_url_id: nil).count} streams to use StreamUrls"
  end
  
  def down
    # Remove stream_url associations and restore link data from stream_urls
    Stream.joins(:stream_url).find_each do |stream|
      stream.update_columns(
        link: stream.stream_url.url,
        stream_url_id: nil
      )
    end
    
    # Delete all stream_urls
    StreamUrl.delete_all
  end
end
