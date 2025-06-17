# == Schema Information
#
# Table name: annotations
#
#  id                  :bigint           not null, primary key
#  user_id             :bigint           not null
#  event_timestamp     :datetime         not null
#  title               :string(200)      not null
#  description         :text
#  event_type          :string           not null
#  priority_level      :string           not null, default("medium")
#  review_status       :string           not null, default("pending")
#  location            :string
#  latitude            :decimal(10,6)
#  longitude           :decimal(10,6)
#  tags                :text
#  external_url        :string
#  requires_review     :boolean          default(false)
#  resolved_at         :datetime
#  resolved_by_user_id :bigint
#  resolution_notes    :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class Annotation < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :resolved_by_user, class_name: 'User', optional: true
  has_many :annotation_streams, dependent: :destroy
  has_many :streams, through: :annotation_streams
  has_many :notes, as: :notable, dependent: :destroy
  
  # Enums
  enum :event_type, {
    breaking_news: 'breaking_news',         # Breaking news event
    emergency: 'emergency',                 # Emergency or crisis
    protest: 'protest',                     # Protest or demonstration
    incident: 'incident',                   # Notable incident occurred
    celebrity_sighting: 'celebrity_sighting', # Celebrity or notable person appearance
    sports_event: 'sports_event',           # Sports-related event
    weather_event: 'weather_event',         # Severe weather or natural disaster
    political_event: 'political_event',     # Political rally, speech, etc.
    cultural_event: 'cultural_event',       # Festival, parade, cultural gathering
    traffic_incident: 'traffic_incident',   # Major traffic or transportation issue
    content_flag: 'content_flag',           # Potentially concerning content across streams
    technical_outage: 'technical_outage',   # Major platform or technical outage
    viral_moment: 'viral_moment',           # Something going viral across platforms
    coordinated_action: 'coordinated_action', # Coordinated activity across streams
    other: 'other'                         # Other type of event
  }, prefix: true
  
  enum :priority_level, {
    low: 'low',
    medium: 'medium',
    high: 'high',
    critical: 'critical'
  }, prefix: true
  
  enum :review_status, {
    pending: 'pending',
    in_review: 'in_review',
    reviewed: 'reviewed',
    resolved: 'resolved',
    dismissed: 'dismissed'
  }, prefix: true
  
  # Validations
  validates :title, presence: true, length: { minimum: 3, maximum: 200 }
  validates :description, length: { maximum: 2000 }
  validates :event_timestamp, presence: true
  validates :location, length: { maximum: 100 }
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validates :external_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }
  
  # Scopes
  scope :recent, -> { order(event_timestamp: :desc) }
  scope :created_recently, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :by_priority, ->(priority) { where(priority_level: priority) }
  scope :by_status, ->(status) { where(review_status: status) }
  scope :by_location, ->(location) { where("location ILIKE ?", "%#{location}%") }
  scope :requires_attention, -> { where(requires_review: true) }
  scope :unresolved, -> { where.not(review_status: ['resolved', 'dismissed']) }
  scope :critical_and_high, -> { where(priority_level: ['critical', 'high']) }
  scope :occurred_between, ->(start_time, end_time) { 
    where(event_timestamp: start_time..end_time) 
  }
  scope :occurred_today, -> { occurred_between(Date.current.beginning_of_day, Date.current.end_of_day) }
  scope :occurred_this_week, -> { occurred_between(1.week.ago, Time.current) }
  scope :with_tags, ->(tag_list) {
    where("tags ILIKE ANY (?)", Array(tag_list).map { |tag| "%#{tag}%" })
  }
  scope :near_location, ->(lat, lon, radius_km = 50) {
    where(
      "latitude IS NOT NULL AND longitude IS NOT NULL AND 
       (6371 * acos(cos(radians(?)) * cos(radians(latitude)) * 
       cos(radians(longitude) - radians(?)) + sin(radians(?)) * 
       sin(radians(latitude)))) <= ?",
      lat, lon, lat, radius_km
    )
  }
  
  # Filtering scope for admin interface
  scope :filtered, ->(params) do
    scope = all
    scope = scope.by_type(params[:event_type]) if params[:event_type].present?
    scope = scope.by_priority(params[:priority_level]) if params[:priority_level].present?
    scope = scope.by_status(params[:review_status]) if params[:review_status].present?
    scope = scope.by_location(params[:location]) if params[:location].present?
    scope = scope.where(requires_review: params[:requires_review]) if params[:requires_review].present?
    
    if params[:start_date].present? && params[:end_date].present?
      start_time = Date.parse(params[:start_date]).beginning_of_day
      end_time = Date.parse(params[:end_date]).end_of_day
      scope = scope.occurred_between(start_time, end_time)
    elsif params[:start_date].present?
      start_time = Date.parse(params[:start_date]).beginning_of_day
      scope = scope.where('event_timestamp >= ?', start_time)
    elsif params[:end_date].present?
      end_time = Date.parse(params[:end_date]).end_of_day
      scope = scope.where('event_timestamp <= ?', end_time)
    end
    
    if params[:search].present?
      scope = scope.where(
        'title ILIKE ? OR description ILIKE ? OR location ILIKE ? OR tags ILIKE ?', 
        "%#{params[:search]}%", "%#{params[:search]}%", 
        "%#{params[:search]}%", "%#{params[:search]}%"
      )
    end
    
    scope
  end
  
  # Callbacks
  before_save :auto_flag_for_review
  
  # Instance methods
  def owned_by?(user)
    self.user_id == user&.id
  end
  
  def resolved?
    resolved_at.present? && review_status_resolved?
  end
  
  def needs_attention?
    requires_review? || priority_level_critical? || priority_level_high?
  end
  
  def resolve!(user, notes = nil)
    update!(
      review_status: 'resolved',
      resolved_at: Time.current,
      resolved_by_user: user,
      resolution_notes: notes
    )
  end
  
  def dismiss!(user, notes = nil)
    update!(
      review_status: 'dismissed',
      resolved_at: Time.current,
      resolved_by_user: user,
      resolution_notes: notes
    )
  end
  
  def formatted_event_time
    event_timestamp.strftime("%B %d, %Y at %I:%M %p")
  end
  
  def time_ago
    time_ago_in_words(event_timestamp)
  end
  
  def stream_count
    annotation_streams.count
  end
  
  def has_location?
    latitude.present? && longitude.present?
  end
  
  def location_display
    return location if location.present?
    return "#{latitude.round(4)}, #{longitude.round(4)}" if has_location?
    "Unknown location"
  end
  
  def add_stream!(stream, user, timestamp_seconds: nil, relevance: 3, notes: nil)
    annotation_streams.create!(
      stream: stream,
      added_by_user: user,
      stream_timestamp_seconds: timestamp_seconds,
      relevance_score: relevance,
      stream_notes: notes
    )
  end
  
  def remove_stream!(stream)
    annotation_streams.find_by(stream: stream)&.destroy
  end
  
  def tag_list
    return [] if tags.blank?
    
    # Handle both JSON array and comma-separated formats
    begin
      JSON.parse(tags)
    rescue JSON::ParserError
      tags.split(',').map(&:strip).reject(&:blank?)
    end
  end
  
  def tag_list=(new_tags)
    if new_tags.is_a?(Array)
      self.tags = new_tags.reject(&:blank?).to_json
    elsif new_tags.is_a?(String)
      tag_array = new_tags.split(',').map(&:strip).reject(&:blank?)
      self.tags = tag_array.to_json
    else
      self.tags = [].to_json
    end
  end
  
  def priority_color
    case priority_level
    when 'critical' then 'text-red-600 bg-red-100'
    when 'high' then 'text-orange-600 bg-orange-100'
    when 'medium' then 'text-yellow-600 bg-yellow-100'
    when 'low' then 'text-gray-600 bg-gray-100'
    else 'text-gray-600 bg-gray-100'
    end
  end
  
  def status_color
    case review_status
    when 'pending' then 'text-yellow-600 bg-yellow-100'
    when 'in_review' then 'text-blue-600 bg-blue-100'
    when 'reviewed' then 'text-green-600 bg-green-100'
    when 'resolved' then 'text-green-600 bg-green-100'
    when 'dismissed' then 'text-gray-600 bg-gray-100'
    else 'text-gray-600 bg-gray-100'
    end
  end
  
  private
  
  def auto_flag_for_review
    self.requires_review = true if priority_level_critical? || 
                                   event_type_emergency? || 
                                   event_type_content_flag?
  end
end