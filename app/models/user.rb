# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email           :string           not null
#  password_digest :string           not null
#  role            :string           default("default")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null

  # Enums
  enum role: {
    default: 'default',
    editor: 'editor', 
    admin: 'admin'
  }
  
  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }, 
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, 
                      format: {
                        with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
                        message: "must include lowercase, uppercase, and number"
                      }, 
                      on: :create
  validates :role, inclusion: { in: roles.keys }
  
  # Scopes
  scope :editors, -> { where(role: 'editor') }
  scope :admins, -> { where(role: 'admin') }
  
  # Callbacks
  before_validation :normalize_email
  
  # Instance methods
  def can_modify_streams?
    editor? || admin?
  end
  
  # Override Devise's password= to ensure bcrypt is used
  def password=(new_password)
    @password = new_password
    self.password_digest = BCrypt::Password.create(new_password) if new_password.present?
  end
  
  # For Devise compatibility
  def encrypted_password
    password_digest
  end
  
  def encrypted_password=(value)
    self.password_digest = value
  end
  
  private
  
  def normalize_email
    self.email = email&.downcase&.strip
  end
end