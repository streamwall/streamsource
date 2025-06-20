class CreateTimestamps < ActiveRecord::Migration[8.0]
  def change
    # Main timestamps table - represents real-world events
    create_table :timestamps do |t|
      # Event metadata
      t.references :user, null: false, foreign_key: true # Who created the timestamp
      t.datetime :event_timestamp, null: false # When the real-world event occurred
      
      # Event content
      t.string :title, null: false, limit: 200
      t.text :description
      
      t.timestamps
    end
    
    # Join table - links timestamps to streams that captured the event
    create_table :timestamp_streams do |t|
      t.references :timestamp, null: false, foreign_key: true
      t.references :stream, null: false, foreign_key: true
      t.references :added_by_user, null: false, foreign_key: { to_table: :users }
      
      # Stream-specific context
      t.integer :stream_timestamp_seconds # Where in this stream the event appears
      t.string :stream_timestamp_display # Human readable like "1:23:45"
      
      t.timestamps
    end
    
    # Indexes for performance
    add_index :timestamps, :event_timestamp
    
    add_index :timestamp_streams, [:timestamp_id, :stream_id], unique: true
    # Note: t.references :stream already creates an index on stream_id
    add_index :timestamp_streams, :stream_timestamp_seconds
  end
end