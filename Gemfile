source "https://rubygems.org"

ruby "3.3.6"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.0"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0.1"

# Hotwire's SPA-like page accelerator
gem "turbo-rails"

# Hotwire's modest JavaScript framework
gem "stimulus-rails"

# Bundle and process CSS
gem "cssbundling-rails"

# Bundle and transpile JavaScript
gem "jsbundling-rails"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"

# Authentication
gem "jwt"
gem "devise", "~> 4.9"
gem "devise-jwt", "~> 0.11"

# Authorization
gem "pundit", "~> 2.3"

# Rate limiting and security
gem "rack-attack", "~> 6.7"

# Pagination
gem "kaminari", "~> 1.2"
gem "pagy", "~> 6.2"

# Serialization
gem "active_model_serializers", "~> 0.10.14"

# API Documentation
gem "rswag-api"
gem "rswag-ui"

# Feature flags
gem "flipper", "~> 1.3"
gem "flipper-active_record", "~> 1.3"
gem "flipper-ui", "~> 1.3"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  # gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Testing
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
  gem "shoulda-matchers", "~> 6.0"
  gem "database_cleaner-active_record", "~> 2.1"
  gem "rails-controller-testing", "~> 1.0"
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  # Better error pages
  gem "better_errors"
  gem "binding_of_caller"

  # N+1 query detection
  gem "bullet"
end

group :test do
  gem "rswag-specs"
  gem "simplecov", require: false
  gem "webmock", "~> 3.19"
  gem "vcr", "~> 6.2"
end

# Performance monitoring
# gem "skylight", "~> 6.0" # or gem "appsignal", "~> 3.5"

# Background jobs (if needed later)
# gem "sidekiq", "~> 7.2"

# Logging
gem "lograge", "~> 0.14"