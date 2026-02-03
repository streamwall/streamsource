class AddStreamTablePreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :stream_table_preferences, :jsonb, default: {}, null: false
  end
end
