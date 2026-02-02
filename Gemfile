source "https://rubygems.org"

ruby "4.0.1"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.2"

# Use postgresql as the database for Active Record
gem "pg"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma"

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

# Asset pipeline
gem "propshaft"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Ruby 4 removed some stdlib gems from default install.
gem "ostruct"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"

# Authentication
gem "devise"
gem "devise-jwt"
gem "jwt"

# Authorization
gem "pundit"

# Rate limiting and security
gem "rack-attack"

# Pagination
gem "pagy"

# Serialization
gem "active_model_serializers"

# API Documentation
gem "rswag-api"
gem "rswag-ui"

# Feature flags
gem "flipper"
gem "flipper-active_record"
gem "flipper-ui"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Dependency vulnerability scanning
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Performance profiling for CI performance checks
  gem "memory_profiler", require: false

  # Ruby style guide enforcement
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false

  # Testing
  gem "database_cleaner-active_record"
  gem "factory_bot_rails"
  gem "faker"
  gem "rails-controller-testing"
  gem "rspec-rails"
  gem "shoulda-matchers"
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  # N+1 query detection
  gem "bullet"
end

group :test do
  gem "rswag-specs"
  gem "simplecov", require: false
  gem "vcr"
  gem "webmock"
end

# Performance monitoring
# gem "skylight", "~> 6.0" # or gem "appsignal", "~> 3.5"

# Background jobs (if needed later)
# gem "sidekiq", "~> 7.2"

# Logging
gem "lograge"
