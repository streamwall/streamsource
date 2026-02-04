# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Load feature flags first so models can reference them during seed data creation.
load Rails.root.join("db/seeds/feature_flags.rb")

# Only create default users in development and test environments
if Rails.env.local?
  # Create default admin user
  admin = User.find_or_create_by!(email: "admin@example.com") do |user|
    user.password = "Password123!"
    user.role = "admin"
  end

  if admin.previously_new_record?
    Rails.logger.debug { "Admin user created: #{admin.email} (password: Password123!)" }
  else
    Rails.logger.debug { "Admin user already exists: #{admin.email}" }
  end

  # Create second admin user for testing multiplayer
  admin2 = User.find_or_create_by!(email: "admin2@example.com") do |user|
    user.password = "Password123!"
    user.role = "admin"
  end

  if admin2.previously_new_record?
    Rails.logger.debug { "Second admin user created: #{admin2.email} (password: Password123!)" }
  else
    Rails.logger.debug { "Second admin user already exists: #{admin2.email}" }
  end

  # Create editor user
  editor = User.find_or_create_by!(email: "editor@example.com") do |user|
    user.password = "Password123!"
    user.role = "editor"
  end

  if editor.previously_new_record?
    Rails.logger.debug { "Editor user created: #{editor.email} (password: Password123!)" }
  else
    Rails.logger.debug { "Editor user already exists: #{editor.email}" }
  end

  # Create default user
  default_user = User.find_or_create_by!(email: "user@example.com") do |user|
    user.password = "Password123!"
    user.role = "default"
  end

  if default_user.previously_new_record?
    Rails.logger.debug { "Default user created: #{default_user.email} (password: Password123!)" }
  else
    Rails.logger.debug { "Default user already exists: #{default_user.email}" }
  end

  Rails.logger.debug "\n========================================"
  Rails.logger.debug "Development Admin Login Credentials:"
  Rails.logger.debug "Admin 1: admin@example.com"
  Rails.logger.debug "Admin 2: admin2@example.com"
  Rails.logger.debug "Password: Password123!"
  Rails.logger.debug "========================================\n"
end

def normalize_seed_platform(value)
  key = value.to_s.strip.downcase
  StreamerAccount.platforms.key?(key) ? key : nil
end

def find_or_create_seed_streamer(stream_data, user)
  name = stream_data[:streamer_name].presence || stream_data[:source]
  return nil if name.blank?

  streamer = Streamer.find_or_create_by!(name: name) do |record|
    record.user = user
    record.notes = stream_data[:notes]
    record.posted_by = stream_data[:posted_by]
  end

  platform = normalize_seed_platform(stream_data[:platform])
  username = stream_data[:source].to_s.strip
  if platform.present? && username.present?
    StreamerAccount.find_or_create_by!(streamer: streamer, platform: platform, username: username)
  end

  streamer
end

# Create sample streams
if Stream.none? && Rails.env.local?
  # Get the admin and editor users
  admin = User.find_by(email: "admin@example.com")
  editor = User.find_by(email: "editor@example.com")
  default_user = User.find_by(email: "user@example.com")

  unless admin && editor && default_user
    Rails.logger.debug "Skipping stream creation - users not found"
    return
  end
  # Create realistic sample streams for admin
  sample_streams = [
    {
      source: "nyc_streamer",
      link: "https://www.tiktok.com/@nyc_streamer/live",
      platform: "tiktok",
      status: "live",
      city: "New York",
      state: "NY",
      title: "Live from Times Square",
      notes: "24/7 Times Square livestream",
      posted_by: "admin_discord",
      orientation: "vertical",
      kind: "video",
      is_pinned: true,
    },
    {
      source: "protest_watch",
      link: "https://www.twitch.tv/protest_watch",
      platform: "twitch",
      status: "offline",
      city: "Los Angeles",
      state: "CA",
      title: "LA Protest Coverage",
      notes: "Covers major protests and demonstrations",
      posted_by: "watcher_twitch",
      orientation: "horizontal",
      kind: "video",
      is_pinned: true,
    },
    {
      source: "weather_cam_chicago",
      link: "https://www.youtube.com/watch?v=weather123",
      platform: "youtube",
      status: "live",
      city: "Chicago",
      state: "IL",
      title: "Chicago Weather Cam",
      notes: "Downtown Chicago weather camera",
      posted_by: "weatherfan",
      orientation: "horizontal",
      kind: "video",
    },
    {
      source: "seattle_traffic",
      link: "https://www.facebook.com/seattletraffic/live",
      platform: "facebook",
      status: "unknown",
      city: "Seattle",
      state: "WA",
      title: "I-5 Traffic Cam",
      notes: "Traffic monitoring stream",
      posted_by: "trafficwatch",
      orientation: "horizontal",
      kind: "web",
    },
    {
      source: "miami_beach_cam",
      link: "https://www.instagram.com/miamibeachcam/live",
      platform: "instagram",
      status: "live",
      city: "Miami",
      state: "FL",
      title: "Miami Beach Live",
      notes: "South Beach live camera",
      posted_by: "beachfan99",
      orientation: "vertical",
      kind: "video",
    },
  ]

  sample_streams.each do |stream_data|
    streamer = find_or_create_seed_streamer(stream_data, admin)
    Stream.create!(
      **stream_data,
      user: admin,
      streamer: streamer,
      last_checked_at: rand(1..24).hours.ago,
      last_live_at: stream_data[:status] == "live" ? rand(1..6).hours.ago : rand(1..30).days.ago,
    )
  end

  Rails.logger.debug { "Created #{sample_streams.count} sample streams for admin user" }

  # Create sample streams for editor
  editor_streams = [
    {
      source: "boston_news",
      link: "https://www.tiktok.com/@boston_news/live",
      platform: "tiktok",
      status: "live",
      city: "Boston",
      state: "MA",
      title: "Boston Breaking News",
      notes: "Local news coverage",
      posted_by: "editor_discord",
      orientation: "vertical",
      kind: "video",
    },
    {
      source: "denver_weather",
      link: "https://www.twitch.tv/denver_weather",
      platform: "twitch",
      status: "offline",
      city: "Denver",
      state: "CO",
      title: "Denver Weather Station",
      notes: "Mountain weather conditions",
      posted_by: "weatherbot",
      orientation: "horizontal",
      kind: "overlay",
    },
    {
      source: "phoenix_traffic",
      link: "https://example.com/phoenix-traffic",
      platform: "other",
      status: "unknown",
      city: "Phoenix",
      state: "AZ",
      title: "I-10 Traffic Monitor",
      notes: "Highway traffic cam",
      posted_by: "editor@example.com",
      orientation: "horizontal",
      kind: "web",
    },
  ]

  editor_streams.each do |stream_data|
    streamer = find_or_create_seed_streamer(stream_data, editor)
    Stream.create!(
      **stream_data,
      user: editor,
      streamer: streamer,
      last_checked_at: rand(1..48).hours.ago,
      last_live_at: stream_data[:status] == "live" ? rand(1..12).hours.ago : nil,
    )
  end

  Rails.logger.debug { "Created #{editor_streams.count} sample streams for editor user" }

  # Create a stream for the default user
  default_stream = {
    source: "user_stream",
    link: "https://www.tiktok.com/@user_stream/live",
    platform: "TikTok",
    status: "Unknown",
    city: "Austin",
    state: "TX",
    title: "Austin City View",
    notes: "Downtown Austin view",
    posted_by: "user@example.com",
    orientation: "vertical",
    kind: "video",
  }

  default_streamer = find_or_create_seed_streamer(default_stream, default_user)
  Stream.create!(
    **default_stream,
    user: default_user,
    streamer: default_streamer,
    last_checked_at: 1.week.ago,
  )

  Rails.logger.debug "Created 1 sample stream for default user"
end
