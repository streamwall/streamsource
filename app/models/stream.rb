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
  enum :status, {
    active: 'active',
    inactive: 'inactive'
  }, default: 'active'
  
  # Validations
  validates :url, presence: true, 
                  format: { 
                    with: ApplicationConstants::Stream::URL_REGEX,
                    message: ApplicationConstants::Stream::URL_ERROR_MESSAGE
                  }
  validates :name, presence: true, 
                   length: { 
                     minimum: ApplicationConstants::Stream::NAME_MIN_LENGTH, 
                     maximum: ApplicationConstants::Stream::NAME_MAX_LENGTH 
                   }
  validates :user, presence: true
  
  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :pinned, -> { where(is_pinned: true) }
  scope :unpinned, -> { where(is_pinned: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :ordered, -> { order(is_pinned: :desc, created_at: :desc) }
  
  # Filtering scope for admin interface
  scope :filtered, ->(params) do
    scope = all
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
    scope = scope.where(is_pinned: params[:is_pinned]) if params[:is_pinned].present?
    if params[:search].present?
      scope = scope.where('name ILIKE ? OR url ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%")
    end
    scope
  end
  
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