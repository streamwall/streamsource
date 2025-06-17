class CreateAnnotations < ActiveRecord::Migration[8.0]
  def change
    # Main annotations table - represents real-world events
    create_table :annotations do |t|
      # Event metadata
      t.references :user, null: false, foreign_key: true # Who created the annotation
      t.datetime :event_timestamp, null: false # When the real-world event occurred
      
      # Event content
      t.string :title, null: false, limit: 200
      t.text :description
      t.string :event_type, null: false
      t.string :priority_level, null: false, default: 'medium'
      t.string :review_status, null: false, default: 'pending'
      
      # Geographic/contextual information
      t.string :location # City, state, or general location
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      
      # Additional context
      t.text :tags # JSON array of searchable tags
      t.string :external_url # Link to news article, social media, etc.
      t.boolean :requires_review, default: false
      
      # Resolution tracking
      t.datetime :resolved_at
      t.references :resolved_by_user, null: true, foreign_key: { to_table: :users }
      t.text :resolution_notes
      
      t.timestamps
    end
    
    # Join table - links annotations to streams that captured the event
    create_table :annotation_streams do |t|
      t.references :annotation, null: false, foreign_key: true
      t.references :stream, null: false, foreign_key: true
      t.references :added_by_user, null: false, foreign_key: { to_table: :users }
      
      # Stream-specific context
      t.integer :stream_timestamp_seconds # Where in this stream the event appears
      t.string :stream_timestamp_display # Human readable like "1:23:45"
      t.integer :relevance_score, default: 3 # 1-5 how relevant this stream is to the event
      t.text :stream_notes # Notes specific to how event appears in this stream
      
      t.timestamps
    end
    
    # Indexes for performance
    add_index :annotations, :event_timestamp
    add_index :annotations, :event_type
    add_index :annotations, :priority_level
    add_index :annotations, :review_status
    add_index :annotations, :requires_review
    add_index :annotations, :location
    add_index :annotations, [:event_timestamp, :priority_level]
    
    add_index :annotation_streams, [:annotation_id, :stream_id], unique: true
    add_index :annotation_streams, :stream_id
    add_index :annotation_streams, :stream_timestamp_seconds
    add_index :annotation_streams, :relevance_score
  end
end