# == Schema Information
#
# Table name: annotation_streams
#
#  id                         :bigint           not null, primary key
#  annotation_id              :bigint           not null
#  stream_id                  :bigint           not null
#  added_by_user_id           :bigint           not null
#  stream_timestamp_seconds   :integer
#  stream_timestamp_display   :string
#  relevance_score            :integer          default(3)
#  stream_notes               :text
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
class AnnotationStream < ApplicationRecord
  # Associations
  belongs_to :annotation
  belongs_to :stream
  belongs_to :added_by_user, class_name: 'User'
  
  # Validations
  validates :relevance_score, inclusion: { in: 1..5 }
  validates :stream_timestamp_seconds, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :stream_notes, length: { maximum: 1000 }
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_relevance, -> { order(relevance_score: :desc) }
  scope :high_relevance, -> { where(relevance_score: 4..5) }
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
    
    if hours > 0
      "%d:%02d:%02d" % [hours, minutes, remaining_seconds]
    else
      "%d:%02d" % [minutes, remaining_seconds]
    end
  end
  
  def relevance_description
    case relevance_score
    when 5 then "Primary source"
    when 4 then "High relevance"
    when 3 then "Moderate relevance"
    when 2 then "Low relevance"
    when 1 then "Background/context"
    else "Unknown"
    end
  end
  
  def relevance_color
    case relevance_score
    when 5 then 'text-green-700 bg-green-100'
    when 4 then 'text-blue-700 bg-blue-100'
    when 3 then 'text-yellow-700 bg-yellow-100'
    when 2 then 'text-orange-700 bg-orange-100'
    when 1 then 'text-gray-700 bg-gray-100'
    else 'text-gray-700 bg-gray-100'
    end
  end
  
  private
  
  def generate_timestamp_display
    self.stream_timestamp_display = formatted_stream_timestamp if stream_timestamp_seconds.present?
  end
end