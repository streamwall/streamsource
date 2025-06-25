class SimplifyTimestampModel < ActiveRecord::Migration[8.0]
  def change
    # Remove columns from timestamps table if they exist
    remove_column :timestamps, :event_type, :string if column_exists?(:timestamps, :event_type)
    remove_column :timestamps, :priority_level, :string if column_exists?(:timestamps, :priority_level)
    remove_column :timestamps, :review_status, :string if column_exists?(:timestamps, :review_status)
    remove_column :timestamps, :location, :string if column_exists?(:timestamps, :location)
    remove_column :timestamps, :latitude, :decimal if column_exists?(:timestamps, :latitude)
    remove_column :timestamps, :longitude, :decimal if column_exists?(:timestamps, :longitude)
    remove_column :timestamps, :tags, :text if column_exists?(:timestamps, :tags)
    remove_column :timestamps, :external_url, :string if column_exists?(:timestamps, :external_url)
    remove_column :timestamps, :requires_review, :boolean if column_exists?(:timestamps, :requires_review)
    remove_column :timestamps, :resolved_at, :datetime if column_exists?(:timestamps, :resolved_at)
    remove_column :timestamps, :resolved_by_user_id, :bigint if column_exists?(:timestamps, :resolved_by_user_id)
    remove_column :timestamps, :resolution_notes, :text if column_exists?(:timestamps, :resolution_notes)
    
    # Remove columns from timestamp_streams table if they exist
    remove_column :timestamp_streams, :relevance_score, :integer if column_exists?(:timestamp_streams, :relevance_score)
    remove_column :timestamp_streams, :stream_notes, :text if column_exists?(:timestamp_streams, :stream_notes)
    
    # Remove indexes that reference deleted columns
    remove_index :timestamps, :event_type if index_exists?(:timestamps, :event_type)
    remove_index :timestamps, :priority_level if index_exists?(:timestamps, :priority_level)
    remove_index :timestamps, :review_status if index_exists?(:timestamps, :review_status)
    remove_index :timestamps, :requires_review if index_exists?(:timestamps, :requires_review)
    remove_index :timestamps, :location if index_exists?(:timestamps, :location)
    remove_index :timestamps, [:event_timestamp, :priority_level] if index_exists?(:timestamps, [:event_timestamp, :priority_level])
    remove_index :timestamp_streams, :relevance_score if index_exists?(:timestamp_streams, :relevance_score)
  end
end