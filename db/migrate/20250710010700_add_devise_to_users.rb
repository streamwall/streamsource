# frozen_string_literal: true

class AddDeviseToUsers < ActiveRecord::Migration[8.0]
  def self.up
    change_table :users do |t|
      ## Database authenticatable
      # Email already exists, so skip it
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      # t.integer  :sign_in_count, default: 0, null: false
      # t.datetime :current_sign_in_at
      # t.datetime :last_sign_in_at
      # t.string   :current_sign_in_ip
      # t.string   :last_sign_in_ip

      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at
    end

    # Email index already exists, so skip it
    add_index :users, :reset_password_token, unique: true
    # add_index :users, :confirmation_token,   unique: true
    # add_index :users, :unlock_token,         unique: true
    
    # Migrate password_digest to encrypted_password
    reversible do |dir|
      dir.up do
        User.reset_column_information
        User.find_each do |user|
          if user.respond_to?(:password_digest) && user.password_digest.present?
            user.update_column(:encrypted_password, user.password_digest)
          end
        end
        remove_column :users, :password_digest
      end
      
      dir.down do
        add_column :users, :password_digest, :string, null: false, default: ""
        User.reset_column_information
        User.find_each do |user|
          if user.encrypted_password.present?
            user.update_column(:password_digest, user.encrypted_password)
          end
        end
      end
    end
  end

  def self.down
    change_table :users do |t|
      t.remove :encrypted_password
      t.remove :reset_password_token
      t.remove :reset_password_sent_at
      t.remove :remember_created_at
    end
    
    remove_index :users, :reset_password_token
  end
end