# frozen_string_literal: true

# Assuming you have not yet modified this file, each configuration option below
# is set to its default value. Note that some are commented out while others
# are not: uncommented lines are intended to protect your configuration from
# breaking changes in upgrades (i.e., in the event that future versions of
# Devise change the default values for those options).

Devise.setup do |config|
  # The secret key used by Devise. Devise uses this key to generate
  # random tokens. Changing this key will render invalid all existing
  # confirmation, reset password and unlock tokens in the database.
  config.secret_key = Rails.application.credentials.secret_key_base

  # ==> JWT Configuration
  config.jwt do |jwt|
    jwt.secret = Rails.application.credentials.devise&.dig(:jwt_secret_key) || Rails.application.secret_key_base
    jwt.dispatch_requests = [
      ["POST", %r{^/api/v1/login$}],
    ]
    jwt.revocation_requests = [
      ["DELETE", %r{^/api/v1/logout$}],
    ]
    jwt.expiration_time = 1.day.to_i
  end

  # ==> Controller configuration
  # Configure the parent class to the devise controllers.
  config.parent_controller = "ApplicationController"

  # ==> Mailer Configuration
  config.mailer_sender = "please-change-me-at-config-initializers-devise@example.com"

  # ==> ORM configuration
  require "devise/orm/active_record"

  # ==> Configuration for any authentication mechanism
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = %i[http_auth jwt]

  # ==> Configuration for :database_authenticatable
  config.stretches = Rails.env.test? ? 1 : 12

  # ==> Configuration for :validatable
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # ==> Navigation configuration
  config.navigational_formats = []

  # When using OmniAuth, Devise cannot automatically set OmniAuth path,
  # so you need to do it manually. For the users scope, it would be:
  # config.omniauth_path_prefix = '/my_engine/users/auth'

  # ==> API only configuration
  config.navigational_formats = [:json]
end
