class Location < ApplicationRecord
  # Associations
  has_many :streams, dependent: :nullify

  # Validations
  validates :city, presence: true
  validates :normalized_name, presence: true, uniqueness: true
  validates :is_known_city, inclusion: { in: [true, false] }

  # Callbacks
  before_validation :set_normalized_name

  # Scopes
  scope :ordered, -> { order(:city, :state_province) }
  scope :by_country, ->(country) { where(country: country) if country.present? }
  scope :by_state, ->(state) { where(state_province: state) if state.present? }
  scope :known_cities, -> { where(is_known_city: true) }
  scope :search, ->(query) {
    return all if query.blank?

    where("city ILIKE ? OR state_province ILIKE ? OR region ILIKE ? OR country ILIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%", "%#{query}%")
  }
  scope :search_by_name, ->(query) { search(query) }

  # Class methods
  def self.find_or_create_from_params(params)
    return nil if params[:city].blank?

    normalized = normalize_location_name(params[:city], params[:state_province], params[:country])

    # If location validation is enabled, check if it's a known city
    if defined?(Flipper) && Flipper.enabled?(ApplicationConstants::Features::LOCATION_VALIDATION)
      existing = find_by(normalized_name: normalized)

      # If location exists and is known, return it
      return existing if existing&.is_known_city?

      # If location exists but not known, or doesn't exist, check against known cities
      known_city = known_cities.where(
        "normalized_name = ? OR (city ILIKE ? AND (state_province ILIKE ? OR state_province IS NULL))",
        normalized, params[:city], params[:state_province]
      ).first

      # If no matching known city found, return nil to signal validation failure
      return nil if known_city.nil?

      # Use the known city if found
      return known_city
    end

    # Default behavior when validation is disabled
    find_or_create_by(normalized_name: normalized) do |location|
      location.city = params[:city]
      location.state_province = params[:state_province]
      location.region = params[:region]
      location.country = params[:country]
      location.latitude = params[:latitude]
      location.longitude = params[:longitude]
      location.is_known_city = false
    end
  end

  def self.normalize_location_name(city, state_province = nil, country = nil)
    parts = [city&.strip&.downcase]
    parts << state_province&.strip&.downcase if state_province.present?
    parts << country&.strip&.downcase if country.present?
    parts.compact.join(", ")
  end

  # Instance methods
  def display_name
    parts = [city]
    parts << state_province if state_province.present?
    parts << country if country.present? && state_province.blank?
    parts.compact.join(", ")
  end

  def full_display_name
    parts = [city]
    parts << state_province if state_province.present?
    parts << region if region.present? && state_province.blank?
    parts << country if country.present?
    parts.compact.join(", ")
  end

  def coordinates?
    latitude.present? && longitude.present?
  end

  def coordinates
    return nil unless coordinates?

    [latitude, longitude]
  end

  private

  def set_normalized_name
    self.normalized_name = self.class.normalize_location_name(city, state_province, country)
  end
end
