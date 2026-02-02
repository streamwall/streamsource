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
  belongs_to :user, inverse_of: :timestamps
  has_many :timestamp_streams, dependent: :destroy
  has_many :streams, through: :timestamp_streams

  # Validations
  validates :title, presence: true, length: { minimum: 3, maximum: 200 }
  validates :description, length: { maximum: 2000 }
  validates :event_timestamp, presence: true

  # Scopes
  scope :recent, -> { order(event_timestamp: :desc) }
  scope :created_recently, -> { order(created_at: :desc) }
  scope :occurred_between, lambda { |start_time, end_time|
    where(event_timestamp: start_time..end_time)
  }
  scope :occurred_today, -> { occurred_between(Date.current.beginning_of_day, Date.current.end_of_day) }
  scope :occurred_this_week, -> { occurred_between(1.week.ago, Time.current) }

  # Filtering scope for admin interface
  scope :filtered, lambda { |params|
    scope = all

    if params[:start_date].present? && params[:end_date].present?
      start_time = klass.parse_boundary(params[:start_date], :beginning_of_day)
      end_time = klass.parse_boundary(params[:end_date], :end_of_day)
      scope = scope.occurred_between(start_time, end_time)
    elsif params[:start_date].present?
      start_time = klass.parse_boundary(params[:start_date], :beginning_of_day)
      scope = scope.where(event_timestamp: start_time..)
    elsif params[:end_date].present?
      end_time = klass.parse_boundary(params[:end_date], :end_of_day)
      scope = scope.where(event_timestamp: ..end_time)
    end

    if params[:search].present?
      scope = scope.where(
        "title ILIKE ? OR description ILIKE ?",
        "%#{params[:search]}%", "%#{params[:search]}%"
      )
    end

    scope
  }

  # Instance methods
  def owned_by?(user)
    user_id == user&.id
  end

  def formatted_event_time
    event_timestamp.strftime("%B %d, %Y at %I:%M %p")
  end

  def time_ago
    return nil unless event_timestamp

    seconds = (Time.current - event_timestamp).to_i
    return "just now" if seconds < 60

    format_elapsed_time(seconds)
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

  def self.parse_boundary(value, boundary)
    date = value.is_a?(String) ? Date.parse(value) : value
    date.public_send(boundary)
  end

  private

  def format_elapsed_time(seconds)
    minutes = seconds / 60
    return pluralize_elapsed(minutes, "minute") if minutes < 60

    hours = minutes / 60
    return pluralize_elapsed(hours, "hour") if hours < 24

    days = hours / 24
    return pluralize_elapsed(days, "day") if days < 30

    months = days / 30
    return pluralize_elapsed(months, "month") if months < 12

    years = days / 365
    pluralize_elapsed(years, "year")
  end

  def pluralize_elapsed(value, unit)
    "#{value} #{unit}#{'s' unless value == 1} ago"
  end
end
