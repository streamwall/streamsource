# == Schema Information
#
# Table name: streams
#
#  id              :bigint           not null, primary key
#  link            :string           not null
#  source          :string           not null
#  user_id         :bigint           not null
#  streamer_id     :bigint
#  is_pinned       :boolean          default(false)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  city            :string
#  state           :string
#  platform        :string
#  status          :string           default("Unknown")
#  notes           :text
#  title           :string
#  last_checked_at :datetime
#  last_live_at    :datetime
#  posted_by       :string
#  orientation     :string
#  kind            :string           default("video")
#  started_at      :datetime
#  ended_at        :datetime
#  is_archived     :boolean          default(false)
#
class Stream < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :streamer, optional: true # Optional for now during migration
  belongs_to :location, optional: true
  has_many :timestamp_streams, dependent: :destroy
  has_many :timestamps, through: :timestamp_streams

  # Enums
  enum :status, {
    live: "Live",
    offline: "Offline",
    unknown: "Unknown",
  }, default: "Unknown"

  enum :platform, {
    tiktok: "TikTok",
    facebook: "Facebook",
    twitch: "Twitch",
    youtube: "YouTube",
    instagram: "Instagram",
    other: "Other",
  }, prefix: true

  enum :orientation, {
    vertical: "vertical",
    horizontal: "horizontal",
  }, prefix: true, allow_nil: true

  enum :kind, {
    video: "video",
    web: "web",
    overlay: "overlay",
    background: "background",
  }, default: "video", prefix: true

  # Callbacks for broadcasting
  after_create_commit -> {
    broadcast_prepend_later_to "streams", target: "streams", partial: "admin/streams/stream", locals: { stream: self }
  }
  after_update_commit -> {
    broadcast_replace_later_to "streams", target: "stream_#{id}", partial: "admin/streams/stream",
                                          locals: { stream: self }
    broadcast_time_updates if saved_change_to_last_checked_at? || saved_change_to_last_live_at?
  }
  after_destroy_commit -> { broadcast_remove_to "streams", target: "stream_#{id}" }

  # Validations
  validates :link, presence: true,
                   format: {
                     with: ApplicationConstants::Stream::URL_REGEX,
                     message: ApplicationConstants::Stream::URL_ERROR_MESSAGE,
                   }
  validates :source, presence: true,
                     length: {
                       minimum: ApplicationConstants::Stream::NAME_MIN_LENGTH,
                       maximum: ApplicationConstants::Stream::NAME_MAX_LENGTH,
                     }
  validates :platform, inclusion: { in: platforms.keys }, allow_nil: true
  validates :status, inclusion: { in: statuses.keys }
  validates :orientation, inclusion: { in: orientations.keys }, allow_nil: true
  validates :kind, inclusion: { in: kinds.keys }

  # Scopes
  scope :live, -> { where(status: "Live") }
  scope :offline, -> { where(status: "Offline") }
  scope :unknown_status, -> { where(status: "Unknown") }
  scope :pinned, -> { where(is_pinned: true) }
  scope :unpinned, -> { where(is_pinned: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_streamer, ->(streamer) { where(streamer: streamer) }
  scope :by_platform, ->(platform) { where(platform: platform) }
  scope :by_kind, ->(kind) { where(kind: kind) }
  scope :recently_checked, -> { order(last_checked_at: :desc) }
  scope :recently_live, -> { order(last_live_at: :desc) }
  scope :ordered, -> { order(is_pinned: :desc, started_at: :desc) }

  # Archival scopes
  scope :archived, -> { where(is_archived: true) }
  scope :not_archived, -> { where(is_archived: false) }
  scope :active, -> { not_archived }
  scope :needs_archiving, -> {
    not_archived
      .where.not(status: "Live")
      .where(last_checked_at: ...30.minutes.ago)
  }

  # Filtering scope for admin interface
  scope :filtered, ->(params) do
    scope = all
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(platform: params[:platform]) if params[:platform].present?
    scope = scope.where(kind: params[:kind]) if params[:kind].present?
    scope = scope.where(orientation: params[:orientation]) if params[:orientation].present?
    scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
    scope = scope.where(is_pinned: params[:is_pinned]) if params[:is_pinned].present?
    scope = scope.where(is_archived: params[:is_archived]) if params[:is_archived].present?
    scope = scope.where(location_id: params[:location_id]) if params[:location_id].present?
    if params[:search].present?
      scope = scope.where(
        "source ILIKE ? OR link ILIKE ? OR title ILIKE ? OR city ILIKE ? OR state ILIKE ? OR notes ILIKE ? OR posted_by ILIKE ?",
        "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%",
        "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"
      )
    end
    scope
  end

  after_initialize :process_pending_location
  # Callbacks
  before_validation :normalize_link
  before_validation :set_posted_by
  before_validation :create_or_validate_location
  before_save :update_last_checked_at, if: :status_changed?
  before_save :update_last_live_at, if: -> { status_changed? && live? }
  before_save :set_started_at, if: -> { status_changed? && live? && started_at.blank? }

  # Instance methods

  # Location helpers - delegate to location association
  def city=(value)
    # Store the value for later processing
    @pending_city = value
    super
  end

  def state=(value)
    # Store the value for later processing
    @pending_state = value
    super
  end

  def display_location
    location&.display_name || [city, state].compact.join(", ")
  end

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
    user_id == user&.id
  end

  def duration_in_words
    return nil unless duration

    seconds = duration.to_i
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60

    if hours.positive?
      "#{hours}h #{minutes}m"
    else
      "#{minutes}m"
    end
  end

  def mark_as_live!
    updates = {
      status: "Live",
      last_checked_at: Time.current,
      last_live_at: Time.current,
    }
    updates[:started_at] = Time.current if started_at.blank?
    update!(updates)
  end

  def mark_as_offline!
    update!(status: "Offline", last_checked_at: Time.current)
    # Check if stream should be archived
    archive! if should_archive?
  end

  def mark_as_unknown!
    update!(status: "Unknown", last_checked_at: Time.current)
    # Check if stream should be archived
    archive! if should_archive?
  end

  def archive!
    return if is_archived?

    update!(
      is_archived: true,
      ended_at: ended_at || last_checked_at || Time.current,
    )
  end

  def should_archive?
    return false if is_archived?
    return false if live?

    # Archive if offline/unknown for more than 30 minutes
    last_checked_at.present? && last_checked_at < 30.minutes.ago
  end

  def duration
    return nil if started_at.blank?

    end_time = ended_at || Time.current
    end_time - started_at
  end

  def broadcast_time_updates
    ActionCable.server.broadcast("collaborative_streams", {
                                   action: "stream_updated",
                                   stream_id: id,
                                   last_checked_at: last_checked_at&.iso8601,
                                   last_live_at: last_live_at&.iso8601,
                                 })
  end

  private

  def table_exists?(table_name)
    ActiveRecord::Base.connection.table_exists?(table_name)
  rescue StandardError
    false
  end

  def process_pending_location
    # This ensures we don't lose pending values
    @pending_city ||= city
    @pending_state ||= state
  end

  def create_or_validate_location
    return unless (@pending_city.present? || @pending_state.present?) && table_exists?(:locations)

    # Use the pending values or fall back to the attributes
    city_value = @pending_city || city
    state_value = @pending_state || state

    return if city_value.blank?

    location_result = Location.find_or_create_from_params(
      city: city_value,
      state_province: state_value,
    )

    # Handle the result
    if location_result.is_a?(Location)
      self.location = location_result
    elsif location_result.nil? && Flipper.enabled?(ApplicationConstants::Features::LOCATION_VALIDATION)
      # Location validation is enabled and city is not recognized
      errors.add(:city, "is not a recognized city. Please contact an admin to add it.")
      throw(:abort)
    end
  end


  def normalize_link
    self.link = link&.strip
  end

  def set_posted_by
    # If posted_by is blank and we have a user, use their email
    return unless posted_by.blank? && user.present?

    self.posted_by = user.email
  end

  def update_last_checked_at
    self.last_checked_at = Time.current
  end

  def update_last_live_at
    self.last_live_at = Time.current
  end

  def set_started_at
    self.started_at = Time.current
  end
end
