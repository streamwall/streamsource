# Be sure to restart your server when you modify this file.

# Version of assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Configure propshaft to use the correct asset path
Rails.application.config.assets.prefix = '/assets'

# Since we're using jsbundling-rails and cssbundling-rails,
# we need to ensure the asset helpers use the correct paths
if Rails.env.development? || Rails.env.test?
  # In development, assets are served directly from the builds directory
  Rails.application.config.assets.debug = true
end