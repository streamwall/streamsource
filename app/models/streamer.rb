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

  # Class methods
  def self.resolve_for_stream(stream, candidate_name: nil)
    return nil if stream.nil?
    return nil if stream.user.blank?

    name = candidate_name.presence || stream.source
    return nil if name.blank?

    streamer = find_by_platform_source(stream.platform, stream.source)
    streamer ||= lookup_by_normalized_name(name)
    streamer ||= create_from_stream(stream, name)
    return nil if streamer.nil?

    streamer.ensure_account(platform: stream.platform, source: stream.source)
    streamer
  end

  def self.find_by_platform_source(platform, source)
    return nil if platform.blank? || source.blank?
    return nil unless StreamerAccount.platforms.key?(platform)

    normalized = source.to_s.strip.downcase
    account = StreamerAccount
              .includes(:streamer)
              .where(platform: platform)
              .where("LOWER(username) = ?", normalized)
              .first
    account&.streamer
  end

  def self.lookup_by_normalized_name(name)
    return nil if name.blank?

    Streamer.where("LOWER(name) = ?", name.to_s.strip.downcase).first
  end

  def self.create_from_stream(stream, name)
    return nil if name.blank?
    return nil if stream.user.blank?

    Streamer.create!(
      name: name,
      user: stream.user,
      posted_by: stream.posted_by.presence || stream.user.email,
      notes: stream.notes.presence,
    )
  end

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
  def ensure_account(platform:, source:)
    return if platform.blank? || source.blank?
    return unless StreamerAccount.platforms.key?(platform)

    normalized = source.to_s.strip.downcase
    existing = streamer_accounts
               .where(platform: platform)
               .where("LOWER(username) = ?", normalized)
               .first
    return if existing.present?

    streamer_accounts.create!(platform: platform, username: normalized)
  end

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
