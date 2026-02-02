# == Schema Information
#
# Table name: streamers
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  notes      :text
#  posted_by  :string
#  user_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Streamer < ApplicationRecord
  # Associations
  belongs_to :user, inverse_of: :streamers
  has_many :streamer_accounts, dependent: :destroy, inverse_of: :streamer
  has_many :streams, dependent: :destroy, inverse_of: :streamer
  has_many :timestamp_streams, through: :streams
  has_many :timestamps, through: :timestamp_streams

  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # Scopes
  scope :with_active_accounts, -> { joins(:streamer_accounts).where(streamer_accounts: { is_active: true }).distinct }
  scope :by_platform, lambda { |platform|
    joins(:streamer_accounts).where(streamer_accounts: { platform: platform }).distinct
  }
  scope :with_live_streams, -> { joins(:streams).where(streams: { status: "Live", is_archived: false }).distinct }
  scope :recently_active, -> { joins(:streams).where(streams: { last_live_at: 7.days.ago.. }).distinct }
  scope :search, ->(query) { where("streamers.name ILIKE ?", "%#{query}%") }

  # Callbacks
  before_validation :normalize_name
  before_save :set_posted_by

  # Instance methods
  def active_stream
    streams.live.not_archived.order(started_at: :desc).first
  end

  def last_stream
    streams.order(started_at: :desc).first
  end

  def platforms
    streamer_accounts.where(is_active: true).pluck(:platform).uniq
  end

  def account_for_platform(platform)
    streamer_accounts.find_by(platform: platform, is_active: true)
  end

  def create_or_continue_stream!(attributes = {})
    # Check if there's an existing non-archived stream that's still "live" or was recently offline
    recent_stream = streams.not_archived
                           .where("last_checked_at > ?", 30.minutes.ago)
                           .order(started_at: :desc)
                           .first

    if recent_stream
      # Continue the existing stream
      recent_stream.update!(attributes.merge(status: "Live", last_checked_at: Time.current, last_live_at: Time.current))
      recent_stream
    else
      # Create a new stream
      streams.create!(attributes.merge(
                        started_at: Time.current,
                        status: "Live",
                        last_checked_at: Time.current,
                        last_live_at: Time.current,
                        user: user,
                      ))
    end
  end

  private

  def normalize_name
    self.name = name&.strip if name_changed?
  end

  def set_posted_by
    self.posted_by ||= user.email if user.present?
  end
end
