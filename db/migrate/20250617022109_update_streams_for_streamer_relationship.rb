class UpdateStreamsForStreamerRelationship < ActiveRecord::Migration[8.0]
  def change
    # Add new columns
    add_reference :streams, :streamer, foreign_key: true
    add_column :streams, :started_at, :datetime
    add_column :streams, :ended_at, :datetime
    add_column :streams, :is_archived, :boolean, default: false
    
    # Add indexes
    add_index :streams, :started_at
    add_index :streams, :ended_at
    add_index :streams, :is_archived
    add_index :streams, [:streamer_id, :is_archived]
    
    # Remove source column since it's now on the streamer
    # We'll handle data migration in a separate task
    # remove_column :streams, :source, :string
  end
end
