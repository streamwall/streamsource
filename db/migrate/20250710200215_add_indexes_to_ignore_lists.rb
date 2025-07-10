class AddIndexesToIgnoreLists < ActiveRecord::Migration[8.0]
  def change
    add_index :ignore_lists, :list_type
    add_index :ignore_lists, [:list_type, :value], unique: true
    add_index :ignore_lists, :value
  end
end
