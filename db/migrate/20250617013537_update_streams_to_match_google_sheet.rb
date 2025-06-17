class UpdateStreamsToMatchGoogleSheet < ActiveRecord::Migration[8.0]
  def change
    # Rename existing fields to match Google Sheet naming
    rename_column :streams, :name, :source
    rename_column :streams, :url, :link
    
    # Remove the existing status column (we'll recreate it with new values)
    remove_column :streams, :status, :string
    
    # Add new fields from Google Sheet
    add_column :streams, :city, :string
    add_column :streams, :state, :string
    add_column :streams, :platform, :string
    add_column :streams, :status, :string, default: "Unknown"
    add_column :streams, :notes, :text
    add_column :streams, :title, :string
    add_column :streams, :last_checked_at, :datetime
    add_column :streams, :last_live_at, :datetime
    add_column :streams, :posted_by, :string
    add_column :streams, :orientation, :string
    add_column :streams, :kind, :string, default: "video"
    
    # Add indexes for commonly queried fields
    add_index :streams, :platform
    add_index :streams, :status
    add_index :streams, :kind
    add_index :streams, :last_checked_at
    add_index :streams, :last_live_at
    
    # Note: created_at already exists and serves as "Added Date"
    # Note: user_id relationship can map to posted_by for authenticated users
  end
end
