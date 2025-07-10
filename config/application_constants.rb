# frozen_string_literal: true

module ApplicationConstants
  # JWT Configuration
  module JWT
    ALGORITHM = "HS256"
    EXPIRATION_TIME = 24.hours
  end

  # Pagination
  module Pagination
    DEFAULT_PAGE = 1
    DEFAULT_PER_PAGE = 25
    MAX_PER_PAGE = 100
  end

  # Password Requirements
  module Password
    MIN_LENGTH = 8
    COMPLEXITY_REGEX = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d).*\z/
    COMPLEXITY_MESSAGE = "must include lowercase, uppercase, and number"
  end

  # Stream Constraints
  module Stream
    NAME_MIN_LENGTH = 1
    NAME_MAX_LENGTH = 255
    URL_REGEX = URI::DEFAULT_PARSER.make_regexp(%w[http https])
    URL_ERROR_MESSAGE = "must be a valid HTTP or HTTPS URL"
  end

  # Rate Limiting
  module RateLimit
    # General requests
    REQUESTS_PER_MINUTE = 1000

    # Login attempts
    LOGIN_ATTEMPTS_PER_PERIOD = 500
    LOGIN_PERIOD = 20.minutes

    # Signup attempts
    SIGNUP_ATTEMPTS_PER_PERIOD = 300
    SIGNUP_PERIOD = 1.hour

    # Exponential backoff levels
    BACKOFF_LEVELS = (2..6)
    BACKOFF_BASE = 8
  end

  # Application Info
  module App
    VERSION = "1.0.0"
    NAME = "StreamSource API"
  end

  # Database
  module Database
    HEALTH_CHECK_QUERY = "SELECT 1"
  end

  # HTTP Status Messages
  module Messages
    UNAUTHORIZED = "Unauthorized"
    FORBIDDEN = "You are not authorized to perform this action"
    NOT_FOUND = "Record not found"
    INVALID_CREDENTIALS = "Invalid email or password"
    RATE_LIMITED = "Too many requests. Please try again later."
    HEALTH_OK = "ok"
    HEALTH_HEALTHY = "healthy"
    HEALTH_READY = "ready"
    HEALTH_NOT_READY = "not ready"
    DATABASE_CONNECTED = "connected"
  end

  # Feature Flags
  module Features
    # Stream features
    STREAM_ANALYTICS = :stream_analytics
    STREAM_BULK_IMPORT = :stream_bulk_import
    STREAM_EXPORT = :stream_export
    STREAM_WEBHOOKS = :stream_webhooks
    STREAM_TAGS = :stream_tags
    STREAM_SCHEDULING = :stream_scheduling

    # User features
    USER_PROFILE_CUSTOMIZATION = :user_profile_customization
    USER_TWO_FACTOR_AUTH = :user_two_factor_auth
    USER_API_KEYS = :user_api_keys
    USER_ACTIVITY_LOG = :user_activity_log

    # API features
    API_GRAPHQL = :api_graphql
    API_WEBSOCKETS = :api_websockets
    API_V2 = :api_v2

    # System features
    ADVANCED_SEARCH = :advanced_search
    REAL_TIME_NOTIFICATIONS = :real_time_notifications
    MAINTENANCE_MODE = :maintenance_mode
    LOCATION_VALIDATION = :location_validation

    # Experimental features
    AI_STREAM_RECOMMENDATIONS = :ai_stream_recommendations
    COLLABORATIVE_PLAYLISTS = :collaborative_playlists
  end
end
