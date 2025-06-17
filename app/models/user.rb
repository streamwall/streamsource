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
  has_secure_password

  # Associations
  has_many :streams, dependent: :destroy
  has_many :streamers, dependent: :destroy

  # Flipper actor
  def flipper_id
    "User:#{id}"
  end

  # Enums
  enum :role, {
    default: 'default',
    editor: 'editor', 
    admin: 'admin'
  }, default: 'default'
  
  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }, 
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: ApplicationConstants::Password::MIN_LENGTH }, 
                      format: {
                        with: ApplicationConstants::Password::COMPLEXITY_REGEX,
                        message: ApplicationConstants::Password::COMPLEXITY_MESSAGE
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
  
  private
  
  def normalize_email
    self.email = email&.downcase&.strip
  end
end