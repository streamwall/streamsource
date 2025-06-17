class CreateStreams < ActiveRecord::Migration[8.0]
  def change
    create_table :streams do |t|
      t.string :url, null: false
      t.string :name, null: false
      t.references :user, null: false, foreign_key: true
      t.string :status, default: 'active'
      t.boolean :is_pinned, default: false
      
      t.timestamps
    end
    
    add_index :streams, :status
    add_index :streams, :is_pinned
    add_index :streams, [:user_id, :created_at]
  end
end