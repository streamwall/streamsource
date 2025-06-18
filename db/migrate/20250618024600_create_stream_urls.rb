class CreateStreamUrls < ActiveRecord::Migration[8.0]
  def change
    create_table :stream_urls do |t|
      t.string :url, null: false
      t.string :url_type, default: 'stream' # 'stream', 'permalink', 'archive'
      t.string :platform
      t.string :title
      t.text :notes
      t.boolean :is_active, default: true
      t.references :streamer, null: false, foreign_key: true
      t.references :created_by, polymorphic: true, null: false
      t.datetime :last_checked_at
      t.datetime :expires_at

      t.timestamps
    end
    
    add_index :stream_urls, :title
    add_index :stream_urls, :is_active
    add_index :stream_urls, :url_type
    add_index :stream_urls, :platform
    add_index :stream_urls, [:streamer_id, :is_active]
    add_index :stream_urls, :last_checked_at
    add_index :stream_urls, :expires_at
  end
end
