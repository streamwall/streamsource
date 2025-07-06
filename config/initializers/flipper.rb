require "flipper"
require "flipper/adapters/active_record"
require "flipper/middleware/memoizer"

# NOTE: Flipper::Middleware::Memoizer is already added by the flipper gem
# No need to add it manually

# Configure Flipper
Flipper.configure do |config|
  config.adapter do
    Flipper::Adapters::ActiveRecord.new
  end
end

# Register groups
Flipper.register(:admins) do |actor|
  actor.respond_to?(:admin?) && actor.admin?
end

Flipper.register(:editors) do |actor|
  actor.respond_to?(:editor?) && actor.editor?
end

Flipper.register(:beta_users) do |actor|
  actor.respond_to?(:beta_user?) && actor.beta_user?
end

Flipper.register(:premium_users) do |actor|
  actor.respond_to?(:premium?) && actor.premium?
end

# Add flipper_id method to User model for actor identification
module FlipperActor
  def flipper_id
    "User:#{id}"
  end
end

# Include in User model
ActiveSupport.on_load(:active_record) do
  User.include FlipperActor if defined?(User)
end

# Preload all features in production for better performance
if Rails.env.production?
  Rails.application.config.after_initialize do
    Flipper.preload_all
  rescue StandardError => e
    Rails.logger.error "Failed to preload Flipper features: #{e.message}"
  end
end

# Helper method to check features
def feature_enabled?(feature_name, actor = nil)
  Flipper.enabled?(feature_name, actor)
end
