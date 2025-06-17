class CreateStreamers < ActiveRecord::Migration[8.0]
  def change
    create_table :streamers do |t|
      t.string :name, null: false
      t.text :notes
      t.string :posted_by
      t.references :user, null: false, foreign_key: true
      
      t.timestamps
    end
    
    add_index :streamers, :name
  end
end
