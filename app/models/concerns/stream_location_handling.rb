# Location assignment and validation for streams.
module StreamLocationHandling
  extend ActiveSupport::Concern

  included do
    after_initialize :process_pending_location
    before_validation :create_or_validate_location
  end

  # Location helpers - delegate to location association
  def city=(value)
    @pending_city = value
    super
  end

  def state=(value)
    @pending_state = value
    super
  end

  def display_location
    location&.display_name || [city, state].compact.join(", ")
  end

  private

  def process_pending_location
    @pending_city = city if @pending_city.nil?
    @pending_state = state if @pending_state.nil?
  end

  def create_or_validate_location
    return unless pending_location_present?

    location_result = Location.find_or_create_from_params(
      city: pending_city,
      state_province: pending_state,
    )

    handle_location_result(location_result)
  end

  def pending_location_present?
    return false unless table_exists?(:locations)
    return false if pending_city.blank? && pending_state.blank?

    true
  end

  def pending_city
    @pending_city || city
  end

  def pending_state
    @pending_state || state
  end

  def handle_location_result(location_result)
    if location_result.is_a?(Location)
      self.location = location_result
    elsif location_result.nil? && Flipper.enabled?(ApplicationConstants::Features::LOCATION_VALIDATION)
      errors.add(:city, :unrecognized_city)
      throw(:abort)
    end
  end

  def table_exists?(table_name)
    ActiveRecord::Base.connection.table_exists?(table_name)
  rescue StandardError
    false
  end
end
