# Feature flags seed data
puts "Setting up feature flags..."

# Enable some features by default
[
  ApplicationConstants::Features::STREAM_ANALYTICS,
  ApplicationConstants::Features::STREAM_EXPORT,
  ApplicationConstants::Features::ADVANCED_SEARCH
].each do |feature|
  Flipper.enable(feature)
  puts "Enabled feature: #{feature}"
end

# Enable for specific groups
Flipper.enable_group(ApplicationConstants::Features::STREAM_BULK_IMPORT, :editors)
puts "Enabled STREAM_BULK_IMPORT for editors group"

Flipper.enable_group(ApplicationConstants::Features::STREAM_TAGS, :admins)
puts "Enabled STREAM_TAGS for admins group"

# Enable for percentage of actors
Flipper.enable_percentage_of_actors(ApplicationConstants::Features::AI_STREAM_RECOMMENDATIONS, 10)
puts "Enabled AI_STREAM_RECOMMENDATIONS for 10% of users"

# Disable maintenance mode by default
Flipper.disable(ApplicationConstants::Features::MAINTENANCE_MODE)
puts "Disabled MAINTENANCE_MODE"

puts "Feature flags setup complete!"