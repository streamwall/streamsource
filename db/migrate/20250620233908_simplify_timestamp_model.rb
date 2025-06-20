class SimplifyTimestampModel < ActiveRecord::Migration[8.0]
  def change
    # Remove columns from timestamps table
    remove_column :timestamps, :event_type, :string
    remove_column :timestamps, :priority_level, :string
    remove_column :timestamps, :review_status, :string
    remove_column :timestamps, :location, :string
    remove_column :timestamps, :latitude, :decimal
    remove_column :timestamps, :longitude, :decimal
    remove_column :timestamps, :tags, :text
    remove_column :timestamps, :external_url, :string
    remove_column :timestamps, :requires_review, :boolean
    remove_column :timestamps, :resolved_at, :datetime
    remove_column :timestamps, :resolved_by_user_id, :bigint
    remove_column :timestamps, :resolution_notes, :text
    
    # Remove columns from timestamp_streams table
    remove_column :timestamp_streams, :relevance_score, :integer
    remove_column :timestamp_streams, :stream_notes, :text
    
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