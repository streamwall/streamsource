# Blocklist of entities by type.
class IgnoreList < ApplicationRecord
  # List types
  LIST_TYPES = %w[twitch_user discord_user url domain].freeze

  # Validations
  validates :list_type, presence: true, inclusion: { in: LIST_TYPES }
  validates :value, presence: true, uniqueness: { scope: :list_type }

  # Scopes
  scope :twitch_users, -> { where(list_type: "twitch_user") }
  scope :discord_users, -> { where(list_type: "discord_user") }
  scope :urls, -> { where(list_type: "url") }
  scope :domains, -> { where(list_type: "domain") }

  # Normalize values before saving
  before_validation :normalize_value

  private

  def normalize_value
    return if value.blank?

    self.value = case list_type
                 when "twitch_user", "discord_user"
                   value.strip.downcase
                 when "url"
                   normalize_url(value.strip)
                 when "domain"
                   value.strip.downcase.gsub(/^www\./, "")
                 else
                   value.strip
                 end
  end

  def normalize_url(url)
    # Add protocol if missing
    url = "https://#{url}" unless url.match?(%r{^https?://})

    # Remove trailing slashes
    url.gsub(%r{/+$}, "")
  rescue StandardError
    url
  end
end
