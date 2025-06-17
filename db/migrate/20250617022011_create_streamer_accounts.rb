class CreateStreamerAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :streamer_accounts do |t|
      t.references :streamer, null: false, foreign_key: true
      t.string :platform, null: false
      t.string :username, null: false
      t.string :profile_url
      t.boolean :is_active, default: true

      t.timestamps
    end
    
    add_index :streamer_accounts, [:streamer_id, :platform, :username], unique: true, name: 'idx_streamer_platform_username'
    add_index :streamer_accounts, :platform
  end
end
