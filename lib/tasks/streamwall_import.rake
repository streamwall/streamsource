# Streamwall JSON import task.
require "net/http"
require "json"

# Importer for Streamwall JSON data.
# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/BlockLength
class StreamwallImporter
  DEFAULT_URL = "https://script.google.com/macros/s/AKfycbzGOqQ6gF2KASObXEPJ9eXIG63UCk6nMhuxuyFA8AhK" \
                "On6IEZ2NqsY6GyyT1qNE82Cp/exec".freeze
  MODES = %w[upsert skip].freeze
  PLACEHOLDERS = ["", "-", "n/a", "na", "null", "nil", "undefined"].freeze

  def initialize(url:, user:, mode:, dry_run:, limit:, offset:, create_streamers:)
    @url = url
    @user = user
    @mode = mode
    @dry_run = dry_run
    @limit = limit
    @offset = offset
    @create_streamers = create_streamers
  end

  def run
    validate_mode!
    puts "Streamwall import from #{@url}"
    puts "User: #{@user.email} (ID: #{@user.id})"
    puts "Mode: #{@mode} | Dry run: #{@dry_run}"
    puts "Attach streamers to existing streams: #{@create_streamers}"
    puts "Limit: #{@limit || 'none'} | Offset: #{@offset}"

    payload = fetch_json
    rows = extract_rows(payload)
    rows = map_array_rows(rows)
    rows = apply_window(rows)

    if rows.empty?
      puts "No rows found to import."
      return
    end

    results = {
      created: 0,
      updated: 0,
      skipped: 0,
      invalid: 0,
      errors: 0,
    }
    seen_links = Set.new

    rows.each_with_index do |row, index|
      unless row.is_a?(Hash)
        results[:invalid] += 1
        puts "Row #{index}: skipped (non-hash row)"
        next
      end

      attrs = build_attributes(row)
      link = attrs[:link]
      if link.blank?
        results[:invalid] += 1
        puts "Row #{index}: skipped (missing link)"
        next
      end

      link_key = normalize_link_key(link)
      if link_key.nil?
        results[:invalid] += 1
        puts "Row #{index}: skipped (invalid link: #{link})"
        next
      end

      if seen_links.include?(link_key)
        results[:skipped] += 1
        next
      end
      seen_links.add(link_key)

      existing = find_existing_by_link(link)
      if existing
        handle_existing(existing, attrs, results)
      else
        handle_new(attrs, results)
      end
    rescue StandardError => e
      results[:errors] += 1
      puts "Row #{index}: error #{e.class} - #{e.message}"
    end

    puts "Import complete."
    puts "Created: #{results[:created]} | Updated: #{results[:updated]} | Skipped: #{results[:skipped]} | " \
         "Invalid: #{results[:invalid]} | Errors: #{results[:errors]}"
  end

  private

  def validate_mode!
    return if MODES.include?(@mode)

    puts "Invalid MODE=#{@mode}. Allowed: #{MODES.join(', ')}"
    exit 1
  end

  def fetch_json
    response = fetch_response(@url)
    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise "Failed to parse JSON from #{@url}: #{e.message}"
  end

  def fetch_response(url, limit = 5)
    raise "Too many redirects fetching #{url}" if limit <= 0

    uri = URI.parse(url)
    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: 10,
      read_timeout: 30,
    ) do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      request["Accept"] = "application/json"
      http.request(request)
    end

    if response.is_a?(Net::HTTPRedirection)
      location = response["location"]
      raise "Redirect response missing Location header for #{url}" if location.blank?

      next_url = URI.join(url, location).to_s
      return fetch_response(next_url, limit - 1)
    end

    raise "Failed to fetch #{url}: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

    response
  end

  def extract_rows(payload)
    return payload if payload.is_a?(Array)
    return payload["streams"] if payload.is_a?(Hash) && payload["streams"].is_a?(Array)
    return payload["data"] if payload.is_a?(Hash) && payload["data"].is_a?(Array)
    return payload["rows"] if payload.is_a?(Hash) && payload["rows"].is_a?(Array)
    return payload["items"] if payload.is_a?(Hash) && payload["items"].is_a?(Array)

    candidate = payload.is_a?(Hash) ? payload.values.find { |value| value.is_a?(Array) } : nil
    candidate || []
  end

  def map_array_rows(rows)
    return rows unless rows.first.is_a?(Array)

    header = rows.first
    return [] if header.none?

    normalized_header = header.map { |key| normalize_key(key) }
    rows.drop(1).map do |values|
      normalized_header.zip(values).to_h
    end
  end

  def apply_window(rows)
    sliced = rows.drop(@offset)
    return sliced if @limit.nil?

    sliced.first(@limit)
  end

  def handle_existing(existing, attrs, results)
    if @mode == "skip"
      results[:skipped] += 1
      return
    end

    streamer_name = attrs[:streamer_name]
    updates = build_updates(existing, attrs)
    should_attach_streamer = @create_streamers && existing.streamer_id.nil?

    if updates.empty? && !should_attach_streamer
      results[:skipped] += 1
      return
    end

    if @dry_run
      results[:updated] += 1
      return
    end

    existing.assign_attributes(updates) if updates.present?
    if should_attach_streamer
      existing.streamer_name = streamer_name
      existing.assign_streamer_from_source(candidate_name: streamer_name)
    end

    if existing.changed?
      existing.save!
      results[:updated] += 1
    else
      results[:skipped] += 1
    end
  end

  def handle_new(attrs, results)
    if @dry_run
      results[:created] += 1
      return
    end

    streamer_name = attrs.delete(:streamer_name)
    stream = @user.streams.build(attrs)
    stream.streamer_name = streamer_name
    stream.save!
    results[:created] += 1
  end

  def build_updates(existing, attrs)
    updates = {}
    attrs.each do |key, value|
      next if value.nil?
      next if key == :streamer_name

      current = existing.public_send(key)
      next if current.to_s == value.to_s

      updates[key] = value
    end
    updates
  end

  def build_attributes(row)
    normalized = normalize_row(row)
    location = extract_location(normalized)

    source = fetch_value(normalized, "source", "streamer", "streamer_name", "stream", "name", "channel", "creator")
    title = fetch_value(normalized, "title", "stream_title")
    link = normalize_link(fetch_value(normalized, "link", "url", "stream_url", "streamlink"))
    status = normalize_status(fetch_value(normalized, "status", "state"))
    platform = normalize_platform(fetch_value(normalized, "platform", "service"))
    orientation = normalize_orientation(fetch_value(normalized, "orientation"))
    kind = normalize_kind(fetch_value(normalized, "kind", "type"))
    notes = fetch_value(normalized, "notes", "note", "comment", "comments")
    posted_by = fetch_value(normalized, "posted_by", "submitted_by", "owner_email", "email")
    is_pinned = parse_boolean(fetch_value(normalized, "is_pinned", "pinned"))
    is_archived = parse_boolean(fetch_value(normalized, "is_archived", "archived"))
    started_at = parse_time(fetch_value(normalized, "started_at", "start_time", "started", "start"))
    ended_at = parse_time(fetch_value(normalized, "ended_at", "end_time", "ended", "end"))
    last_checked_at = parse_time(fetch_value(normalized, "last_checked_at", "last_checked", "checked_at"))
    last_live_at = parse_time(fetch_value(normalized, "last_live_at", "last_live", "live_at"))

    source = fallback_source(source, title, link)
    platform ||= infer_platform_from_link(link)

    attrs = {
      source: truncate(source, ApplicationConstants::Stream::NAME_MAX_LENGTH),
      link: link,
      title: truncate(title, ApplicationConstants::Stream::NAME_MAX_LENGTH),
      status: status,
      platform: platform,
      orientation: orientation,
      kind: kind,
      notes: notes,
      posted_by: posted_by,
      is_pinned: is_pinned,
      is_archived: is_archived,
      started_at: started_at,
      ended_at: ended_at,
      last_checked_at: last_checked_at,
      last_live_at: last_live_at,
      city: location[:city],
      state: location[:state],
      streamer_name: fetch_value(normalized, "streamer_name", "streamer", "creator"),
    }

    attrs.compact
  end

  def normalize_row(row)
    row.each_with_object({}) do |(key, value), acc|
      acc[normalize_key(key)] = normalize_value(value)
    end
  end

  def normalize_key(key)
    key.to_s.strip.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
  end

  def normalize_value(value)
    return value unless value.is_a?(String)

    normalized = value.strip
    PLACEHOLDERS.include?(normalized.downcase) ? nil : normalized
  end

  def fetch_value(row, *keys)
    keys.each do |key|
      value = row[normalize_key(key)]
      return value if value.present?
    end
    nil
  end

  def extract_location(row)
    location = row["location"]
    if location.is_a?(Hash)
      normalized = normalize_row(location)
      city = fetch_value(normalized, "city")
      state = fetch_value(normalized, "state", "state_province", "province", "region")
      return { city: city, state: state }
    end

    {
      city: fetch_value(row, "city"),
      state: fetch_value(row, "state", "state_province", "province", "region"),
    }
  end

  def normalize_link(value)
    link = normalize_value(value)
    return nil if link.blank?

    link = link.to_s.strip
    link = "https://#{link}" unless link.match?(%r{\Ahttps?://}i)
    link
  end

  def normalize_link_key(link)
    return nil if link.blank?
    return nil unless ApplicationConstants::Stream::URL_REGEX.match?(link)

    normalized = link.strip
    normalized = normalized.chomp("/")
    normalized.downcase
  end

  def find_existing_by_link(link)
    return nil if link.blank?

    normalized = normalize_link_key(link)
    return nil if normalized.nil?

    base = normalized
    variants = [base, "#{base}/"]

    http_variant = base.sub(/\Ahttps:/, "http:")
    https_variant = base.sub(/\Ahttp:/, "https:")
    variants.push(http_variant, "#{http_variant}/", https_variant, "#{https_variant}/")

    candidates = variants.uniq
    Stream.where("LOWER(link) IN (?)", candidates).first
  end

  def fallback_source(source, title, link)
    return source if source.present?
    return title if title.present?

    host = begin
      uri = URI.parse(link)
      uri.host&.sub(/\Awww\./i, "")
    rescue StandardError
      nil
    end
    host.presence || "Stream"
  end

  def truncate(value, max_length)
    return nil if value.blank?

    value.length > max_length ? value[0...max_length] : value
  end

  def normalize_status(value)
    raw = normalize_value(value)
    return nil if raw.blank?

    case raw.to_s.strip.downcase
    when "live", "online", "active"
      "live"
    when "offline", "off", "inactive"
      "offline"
    when "unknown", "n/a", "na"
      "unknown"
    end
  end

  def normalize_platform(value)
    raw = normalize_value(value)
    return nil if raw.blank?

    downcased = raw.to_s.strip.downcase
    return "tiktok" if downcased.include?("tiktok")
    return "facebook" if downcased.include?("facebook") || downcased == "fb"
    return "twitch" if downcased.include?("twitch")
    return "youtube" if downcased.include?("youtube") || downcased == "yt"
    return "instagram" if downcased.include?("instagram") || downcased == "ig"
    return "other" if downcased.include?("other")

    nil
  end

  def infer_platform_from_link(link)
    return nil if link.blank?

    downcased = link.downcase
    return "tiktok" if downcased.include?("tiktok.com")
    return "facebook" if downcased.include?("facebook.com") || downcased.include?("fb.watch")
    return "twitch" if downcased.include?("twitch.tv")
    return "youtube" if downcased.include?("youtube.com") || downcased.include?("youtu.be")
    return "instagram" if downcased.include?("instagram.com")

    nil
  end

  def normalize_orientation(value)
    raw = normalize_value(value)
    return nil if raw.blank?

    case raw.to_s.strip.downcase
    when "vertical", "portrait", "tall"
      "vertical"
    when "horizontal", "landscape", "wide"
      "horizontal"
    end
  end

  def normalize_kind(value)
    raw = normalize_value(value)
    return nil if raw.blank?

    case raw.to_s.strip.downcase
    when "video"
      "video"
    when "web"
      "web"
    when "overlay"
      "overlay"
    when "background", "bg"
      "background"
    end
  end

  def parse_boolean(value)
    raw = normalize_value(value)
    return nil if raw.nil?

    case raw.to_s.strip.downcase
    when "true", "t", "yes", "y", "1"
      true
    when "false", "f", "no", "n", "0"
      false
    end
  end

  def parse_time(value)
    raw = normalize_value(value)
    return nil if raw.blank?

    if raw.is_a?(Numeric) || raw.to_s.match?(/\A\d{10,13}\z/)
      timestamp = raw.to_i
      timestamp /= 1000 if timestamp > 2_000_000_000
      return Time.zone.at(timestamp)
    end

    Time.zone.parse(raw.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/BlockLength

# rubocop:disable Metrics/BlockLength
namespace :streams do
  desc "Import streams from a Streamwall JSON endpoint " \
       "(URL=... USER_EMAIL=... MODE=upsert|skip DRY_RUN=true CREATE_STREAMERS=true)"
  task import_streamwall: :environment do
    url = ENV["URL"] || ENV["STREAMWALL_URL"] || StreamwallImporter::DEFAULT_URL
    mode = (ENV["MODE"] || "upsert").to_s.downcase
    dry_run = ENV.fetch("DRY_RUN", "false").to_s.downcase == "true"
    limit = ENV["LIMIT"]&.to_i
    offset = ENV["OFFSET"].to_i
    create_streamers = ENV.fetch("CREATE_STREAMERS", "true").to_s.downcase == "true"

    user = if ENV["USER_ID"].present?
             User.find(ENV["USER_ID"])
           elsif ENV["USER_EMAIL"].present?
             User.find_by!(email: ENV["USER_EMAIL"])
           else
             User.admins.first || User.first
           end

    if user.nil?
      puts "No users found. Provide USER_EMAIL or USER_ID."
      exit 1
    end

    StreamwallImporter.new(
      url: url,
      user: user,
      mode: mode,
      dry_run: dry_run,
      limit: limit,
      offset: offset,
      create_streamers: create_streamers,
    ).run
  end
end
# rubocop:enable Metrics/BlockLength
