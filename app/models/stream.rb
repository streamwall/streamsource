# == Schema Information
#
# Table name: streams
#
#  id          :bigint           not null, primary key
#  url         :string           not null
#  name        :string           not null
#  user_id     :bigint           not null
#  status      :string           default("active")
#  is_pinned   :boolean          default(false)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Stream < ApplicationRecord
  # Associations
  belongs_to :user
  
  # Enums
  enum status: {
    active: 'active',
    inactive: 'inactive'
  }
  
  # Validations
  validates :url, presence: true, 
                  format: { 
                    with: URI::regexp(%w[http https]),
                    message: "must be a valid HTTP or HTTPS URL"
                  }
  validates :name, presence: true, length: { minimum: 1, maximum: 255 }
  validates :user, presence: true
  
  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :pinned, -> { where(is_pinned: true) }
  scope :unpinned, -> { where(is_pinned: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  
  # Callbacks
  before_validation :normalize_url
  
  # Instance methods
  def pin!
    update!(is_pinned: true)
  end
  
  def unpin!
    update!(is_pinned: false)
  end
  
  def toggle_pin!
    update!(is_pinned: !is_pinned)
  end
  
  def owned_by?(user)
    self.user_id == user&.id
  end
  
  private
  
  def normalize_url
    self.url = url&.strip
  end
end