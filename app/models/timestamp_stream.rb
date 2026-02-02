# == Schema Information
#
# Table name: timestamp_streams
#
#  id                         :bigint           not null, primary key
#  timestamp_id               :bigint           not null
#  stream_id                  :bigint           not null
#  added_by_user_id           :bigint           not null
#  stream_timestamp_seconds   :integer
#  stream_timestamp_display   :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
class TimestampStream < ApplicationRecord
  # Associations
  belongs_to :timestamp, inverse_of: :timestamp_streams
  belongs_to :stream, inverse_of: :timestamp_streams
  belongs_to :added_by_user, class_name: "User", inverse_of: :timestamp_streams

  # Validations
  validates :stream_timestamp_seconds, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :with_timestamp, -> { where.not(stream_timestamp_seconds: nil) }

  # Callbacks
  before_save :generate_timestamp_display

  # Instance methods
  def added_by?(user)
    added_by_user_id == user&.id
  end

  def formatted_stream_timestamp
    return stream_timestamp_display if stream_timestamp_display.present?
    return "Unknown" if stream_timestamp_seconds.blank?

    seconds = stream_timestamp_seconds
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    remaining_seconds = seconds % 60

    if hours.positive?
      format("%<hours>d:%<minutes>02d:%<seconds>02d", hours: hours, minutes: minutes, seconds: remaining_seconds)
    else
      format("%<minutes>d:%<seconds>02d", minutes: minutes, seconds: remaining_seconds)
    end
  end

  private

  def generate_timestamp_display
    self.stream_timestamp_display = formatted_stream_timestamp if stream_timestamp_seconds.present?
  end
end
