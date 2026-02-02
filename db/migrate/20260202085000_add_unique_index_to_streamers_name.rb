class AddUniqueIndexToStreamersName < ActiveRecord::Migration[8.1]
  def change
    add_index :streamers, "LOWER(name)", unique: true, name: "index_streamers_on_lower_name"
  end
end
