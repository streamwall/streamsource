class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.text :content, null: false
      t.references :user, null: false, foreign_key: true
      t.references :notable, polymorphic: true, null: false
      t.timestamps
    end
    
    add_index :notes, [:notable_type, :notable_id]
    add_index :notes, :user_id
    add_index :notes, :created_at
  end
end