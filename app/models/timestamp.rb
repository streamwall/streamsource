# == Schema Information
#
# Table name: timestamps
#
#  id                  :bigint           not null, primary key
#  user_id             :bigint           not null
#  event_timestamp     :datetime         not null
#  title               :string(200)      not null
#  description         :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class Timestamp < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :timestamp_streams, dependent: :destroy
  has_many :streams, through: :timestamp_streams

  # Validations
  validates :title, presence: true, length: { minimum: 3, maximum: 200 }
  validates :description, length: { maximum: 2000 }
  validates :event_timestamp, presence: true

  # Scopes
  scope :recent, -> { order(event_timestamp: :desc) }
  scope :created_recently, -> { order(created_at: :desc) }
  scope :occurred_between, ->(start_time, end_time) {
    where(event_timestamp: start_time..end_time)
  }
  scope :occurred_today, -> { occurred_between(Date.current.beginning_of_day, Date.current.end_of_day) }
  scope :occurred_this_week, -> { occurred_between(1.week.ago, Time.current) }

  # Filtering scope for admin interface
  scope :filtered, ->(params) do
    scope = all

    if params[:start_date].present? && params[:end_date].present?
      start_time = params[:start_date].is_a?(String) ? Date.parse(params[:start_date]).beginning_of_day : params[:start_date].beginning_of_day
      end_time = params[:end_date].is_a?(String) ? Date.parse(params[:end_date]).end_of_day : params[:end_date].end_of_day
      scope = scope.occurred_between(start_time, end_time)
    elsif params[:start_date].present?
      start_time = params[:start_date].is_a?(String) ? Date.parse(params[:start_date]).beginning_of_day : params[:start_date].beginning_of_day
      scope = scope.where(event_timestamp: start_time..)
    elsif params[:end_date].present?
      end_time = params[:end_date].is_a?(String) ? Date.parse(params[:end_date]).end_of_day : params[:end_date].end_of_day
      scope = scope.where(event_timestamp: ..end_time)
    end

    if params[:search].present?
      scope = scope.where(
        "title ILIKE ? OR description ILIKE ?",
        "%#{params[:search]}%", "%#{params[:search]}%"
      )
    end

    scope
  end

  # Instance methods
  def owned_by?(user)
    user_id == user&.id
  end

  def formatted_event_time
    event_timestamp.strftime("%B %d, %Y at %I:%M %p")
  end

  def time_ago
    return nil unless event_timestamp

    seconds = Time.current - event_timestamp
    return "just now" if seconds < 60

    minutes = (seconds / 60).to_i
    return "#{minutes} minute#{'s' if minutes != 1} ago" if minutes < 60

    hours = (minutes / 60).to_i
    return "#{hours} hour#{'s' if hours != 1} ago" if hours < 24

    days = (hours / 24).to_i
    return "#{days} day#{'s' if days != 1} ago" if days < 30

    months = (days / 30).to_i
    return "#{months} month#{'s' if months != 1} ago" if months < 12

    years = (days / 365).to_i
    "#{years} year#{'s' if years != 1} ago"
  end

  def stream_count
    timestamp_streams.count
  end

  def add_stream!(stream, user, timestamp_seconds: nil)
    timestamp_streams.create!(
      stream: stream,
      added_by_user: user,
      stream_timestamp_seconds: timestamp_seconds,
    )
  end

  def remove_stream!(stream)
    timestamp_streams.find_by(stream: stream)&.destroy
  end
end
