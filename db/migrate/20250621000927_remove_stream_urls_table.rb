class RemoveStreamUrlsTable < ActiveRecord::Migration[8.0]
  def change
    # Remove foreign key constraint first
    remove_foreign_key :streams, :stream_urls if foreign_key_exists?(:streams, :stream_urls)
    
    # Remove the stream_url_id column from streams table
    remove_column :streams, :stream_url_id, :bigint if column_exists?(:streams, :stream_url_id)
    
    # Drop the stream_urls table
    drop_table :stream_urls if table_exists?(:stream_urls)
  end
end