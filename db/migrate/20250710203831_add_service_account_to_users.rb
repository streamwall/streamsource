class AddServiceAccountToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :is_service_account, :boolean, default: false, null: false
    add_index :users, :is_service_account
  end
end
