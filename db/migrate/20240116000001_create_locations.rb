class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.string :city, null: false
      t.string :state_province
      t.string :region
      t.string :country
      t.string :normalized_name, null: false
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      
      t.timestamps
    end
    
    add_index :locations, :city
    add_index :locations, :state_province
    add_index :locations, :country
    add_index :locations, :normalized_name, unique: true
    add_index :locations, [:latitude, :longitude]
    add_index :locations, [:city, :state_province, :country]
  end
end