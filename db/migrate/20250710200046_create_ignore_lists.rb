class CreateIgnoreLists < ActiveRecord::Migration[8.0]
  def change
    create_table :ignore_lists do |t|
      t.string :list_type
      t.string :value
      t.text :notes

      t.timestamps
    end
  end
end
