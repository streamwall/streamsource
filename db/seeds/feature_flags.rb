# Feature flags seed data
Rails.logger.debug "Setting up feature flags..."

# Enable some features by default
[
  ApplicationConstants::Features::STREAM_ANALYTICS,
  ApplicationConstants::Features::STREAM_EXPORT,
  ApplicationConstants::Features::ADVANCED_SEARCH,
].each do |feature|
  Flipper.enable(feature)
  Rails.logger.debug { "Enabled feature: #{feature}" }
end

# Enable for specific groups
Flipper.enable_group(ApplicationConstants::Features::STREAM_BULK_IMPORT, :editors)
Rails.logger.debug "Enabled STREAM_BULK_IMPORT for editors group"

Flipper.enable_group(ApplicationConstants::Features::STREAM_TAGS, :admins)
Rails.logger.debug "Enabled STREAM_TAGS for admins group"

# All used feature flags are set above - no experimental features enabled

# Disable maintenance mode by default
Flipper.disable(ApplicationConstants::Features::MAINTENANCE_MODE)
Rails.logger.debug "Disabled MAINTENANCE_MODE"

# Disable location validation by default
Flipper.disable(ApplicationConstants::Features::LOCATION_VALIDATION)
Rails.logger.debug "Disabled LOCATION_VALIDATION"

Rails.logger.debug "Feature flags setup complete!"
