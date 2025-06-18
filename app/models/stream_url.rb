# == Schema Information
#
# Table name: stream_urls
#
#  id               :bigint           not null, primary key
#  url              :string           not null
#  url_type         :string           default("stream")
#  platform         :string
#  title            :string
#  notes            :text
#  is_active        :boolean          default(true)
#  streamer_id      :bigint           not null
#  created_by_type  :string           not null
#  created_by_id    :bigint           not null
#  last_checked_at  :datetime
#  expires_at       :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class StreamUrl < ApplicationRecord
  # Associations
  belongs_to :streamer
  belongs_to :created_by, polymorphic: true
  has_many :streams, dependent: :nullify
  
  # Enums
  enum :url_type, {
    stream: 'stream',        # Current/active stream URL
    permalink: 'permalink',  # Permanent streamer URL (like profile page)
    archive: 'archive'       # Archived/past stream URL
  }, default: 'stream'
  
  enum :platform, {
    tiktok: 'TikTok',
    facebook: 'Facebook', 
    twitch: 'Twitch',
    youtube: 'YouTube',
    instagram: 'Instagram',
    other: 'Other'
  }, prefix: true, allow_nil: true
  
  # Validations
  validates :url, presence: true, 
                  format: { 
                    with: ApplicationConstants::Stream::URL_REGEX,
                    message: ApplicationConstants::Stream::URL_ERROR_MESSAGE
                  }
  validates :url_type, inclusion: { in: url_types.keys }
  validates :platform, inclusion: { in: platforms.keys }, allow_nil: true
  validates :streamer, presence: true
  validates :created_by, presence: true
  
  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :by_type, ->(type) { where(url_type: type) }
  scope :by_platform, ->(platform) { where(platform: platform) }
  scope :by_streamer, ->(streamer) { where(streamer: streamer) }
  scope :recently_checked, -> { order(last_checked_at: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :expires_soon, -> { where('expires_at IS NOT NULL AND expires_at < ?', 1.day.from_now) }
  scope :expired, -> { where('expires_at IS NOT NULL AND expires_at < ?', Time.current) }
  
  # Callbacks
  before_validation :normalize_url
  before_save :update_last_checked_at, if: :url_changed?
  
  # Instance methods
  def activate!
    update!(is_active: true)
  end
  
  def deactivate!
    update!(is_active: false)
  end
  
  def expired?
    expires_at.present? && expires_at < Time.current
  end
  
  def expires_soon?
    expires_at.present? && expires_at < 1.day.from_now
  end
  
  def mark_checked!
    update!(last_checked_at: Time.current)
  end
  
  def owned_by?(user)
    created_by == user
  end
  
  def current_stream?
    url_type == 'stream' && is_active?
  end
  
  def permalink?
    url_type == 'permalink'
  end
  
  def archived?
    url_type == 'archive'
  end
  
  private
  
  def normalize_url
    self.url = url&.strip
  end
  
  def update_last_checked_at
    self.last_checked_at = Time.current
  end
end
