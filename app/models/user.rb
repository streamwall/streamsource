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
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # Associations
  has_many :streams, dependent: :destroy
  has_many :streamers, dependent: :destroy
  has_many :timestamps, dependent: :destroy
  has_many :timestamp_streams, foreign_key: "added_by_user_id", dependent: :destroy

  # Flipper actor
  def flipper_id
    "User:#{id}"
  end

  # Enums
  enum :role, {
    default: "default",
    editor: "editor",
    admin: "admin",
  }, default: "default"

  # Validations (Devise handles email and password validations)
  validates :role, inclusion: { in: roles.keys }
  
  # Override Devise password complexity requirements
  validate :password_complexity, if: :password_required?
  
  def password_complexity
    return if password.blank? || password =~ ApplicationConstants::Password::COMPLEXITY_REGEX
    
    errors.add :password, ApplicationConstants::Password::COMPLEXITY_MESSAGE
  end

  # Scopes
  scope :editors, -> { where(role: "editor") }
  scope :admins, -> { where(role: "admin") }

  # Callbacks
  # Devise handles email normalization

  # Instance methods
  def can_modify_streams?
    editor? || admin?
  end

  def display_name
    email.split("@").first
  end

  # Feature flag groups
  def beta_user?
    # You can implement your own logic here
    # For example: created_at < 30.days.ago || email.ends_with?('@beta.test')
    false
  end

  def premium?
    # Placeholder for premium user logic
    # Could check subscription status, role, etc.
    admin?
  end
  
  # Flipper actor
  def flipper_id
    "User:#{id}"
  end
  
  protected
  
  def password_required?
    new_record? || password.present?
  end
end
