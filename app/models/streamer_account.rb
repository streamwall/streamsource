# == Schema Information
#
# Table name: streamer_accounts
#
#  id          :bigint           not null, primary key
#  streamer_id :bigint           not null
#  platform    :string           not null
#  username    :string           not null
#  profile_url :string
#  is_active   :boolean          default(true)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class StreamerAccount < ApplicationRecord
  # Associations
  belongs_to :streamer, inverse_of: :streamer_accounts

  # Enums
  enum :platform, {
    tiktok: "TikTok",
    facebook: "Facebook",
    twitch: "Twitch",
    youtube: "YouTube",
    instagram: "Instagram",
    other: "Other",
  }, prefix: true

  # Validations
  validates :platform, presence: true, inclusion: { in: platforms.keys }
  validates :username, presence: true
  validates :username, uniqueness: { scope: %i[streamer_id platform],
                                     message: :taken_on_platform }
  validate :profile_url_format

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :by_platform, ->(platform) { where(platform: platform) }

  # Callbacks
  before_validation :normalize_username
  before_save :generate_profile_url

  # Instance methods
  def display_name
    "#{username} (#{platform})"
  end

  def deactivate!
    update!(is_active: false)
  end

  def activate!
    update!(is_active: true)
  end

  private

  def normalize_username
    self.username = username&.strip&.downcase if username_changed?
  end

  def generate_profile_url
    return if profile_url.present?

    self.profile_url = case platform
                       when "tiktok"
                         "https://www.tiktok.com/@#{username}"
                       when "twitch"
                         "https://www.twitch.tv/#{username}"
                       when "youtube", "facebook"
                         # YouTube/Facebook URLs are complex, leave blank for manual entry
                         nil
                       when "instagram"
                         "https://www.instagram.com/#{username}/"
                       end
  end

  def profile_url_format
    return if profile_url.blank?

    return if profile_url.match?(%r{\Ahttps?://}i)

    errors.add(:profile_url, :invalid_url)
  end
end
