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
  include StreamLocationHandling
  include StreamStatusTracking

  # Associations
  belongs_to :user, inverse_of: :streams
  belongs_to :streamer, optional: true, inverse_of: :streams # Optional for now during migration
  belongs_to :location, optional: true, inverse_of: :streams
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

  SORT_COLUMN_MAP = {
    "streamer" => "streamers.name",
    "title" => "streams.title",
    "source" => "streams.source",
    "link" => "streams.link",
    "platform" => "streams.platform",
    "status" => "streams.status",
    "city" => "streams.city",
    "state" => "streams.state",
    "kind" => "streams.kind",
    "orientation" => "streams.orientation",
    "started_at" => "streams.started_at",
    "last_checked_at" => "streams.last_checked_at",
    "last_live_at" => "streams.last_live_at",
  }.freeze
  SORTABLE_COLUMNS = SORT_COLUMN_MAP.keys.freeze

  # Callbacks for broadcasting
  after_create_commit lambda {
    broadcast_prepend_later_to "streams", target: "streams", partial: "admin/streams/stream", locals: { stream: self }
  }
  after_update_commit lambda {
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
  scope :sorted, lambda { |sort_column, direction|
    sort_key = sort_column.to_s
    return ordered unless SORTABLE_COLUMNS.include?(sort_key)

    direction = direction == "asc" ? "asc" : "desc"
    relation = sort_key == "streamer" ? left_joins(:streamer) : self
    order_clause = Arel.sql("#{SORT_COLUMN_MAP.fetch(sort_key)} #{direction} NULLS LAST")

    relation.order(order_clause).order(is_pinned: :desc, started_at: :desc)
  }

  # Archival scopes
  scope :archived, -> { where(is_archived: true) }
  scope :not_archived, -> { where(is_archived: false) }
  scope :active, -> { not_archived }
  scope :needs_archiving, lambda {
    not_archived
      .where.not(status: "Live")
      .where(last_checked_at: ...30.minutes.ago)
  }

  # Filtering scope for admin interface
  scope :filtered, lambda { |params|
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
      term = "%#{params[:search]}%"
      scope = scope.where(
        <<~SQL.squish,
          source ILIKE :term OR link ILIKE :term OR title ILIKE :term OR city ILIKE :term OR
          state ILIKE :term OR notes ILIKE :term OR posted_by ILIKE :term
        SQL
        term: term,
      )
    end
    scope
  }

  # Callbacks
  before_validation :normalize_link
  before_validation :set_posted_by

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
    user_id == user&.id
  end

  private

  def normalize_link
    self.link = link&.strip
  end

  def set_posted_by
    # If posted_by is blank and we have a user, use their email
    return unless posted_by.blank? && user.present?

    self.posted_by = user.email
  end
end
