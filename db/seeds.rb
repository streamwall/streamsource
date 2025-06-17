# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Only create default users in development and test environments
if Rails.env.development? || Rails.env.test?
  # Create default admin user
  admin = User.find_or_create_by!(email: 'admin@example.com') do |user|
    user.password = 'Password123!'
    user.role = 'admin'
  end

  if admin.previously_new_record?
    puts "Admin user created: #{admin.email} (password: Password123!)"
  else
    puts "Admin user already exists: #{admin.email}"
  end

  # Create editor user
  editor = User.find_or_create_by!(email: 'editor@example.com') do |user|
    user.password = 'Password123!'
    user.role = 'editor'
  end

  if editor.previously_new_record?
    puts "Editor user created: #{editor.email} (password: Password123!)"
  else
    puts "Editor user already exists: #{editor.email}"
  end

  # Create default user
  default_user = User.find_or_create_by!(email: 'user@example.com') do |user|
    user.password = 'Password123!'
    user.role = 'default'
  end

  if default_user.previously_new_record?
    puts "Default user created: #{default_user.email} (password: Password123!)"
  else
    puts "Default user already exists: #{default_user.email}"
  end
  
  puts "\n========================================"
  puts "Development Admin Login Credentials:"
  puts "Email: admin@example.com"
  puts "Password: Password123!"
  puts "========================================\n"
end

# Create sample streams
if Stream.count.zero?
  # Create realistic sample streams for admin
  sample_streams = [
    {
      source: "nyc_streamer",
      link: "https://www.tiktok.com/@nyc_streamer/live",
      platform: "TikTok",
      status: "Live",
      city: "New York",
      state: "NY",
      title: "Live from Times Square",
      notes: "24/7 Times Square livestream",
      posted_by: "admin_discord",
      orientation: "vertical",
      kind: "video",
      is_pinned: true
    },
    {
      source: "protest_watch",
      link: "https://www.twitch.tv/protest_watch",
      platform: "Twitch",
      status: "Offline",
      city: "Los Angeles",
      state: "CA",
      title: "LA Protest Coverage",
      notes: "Covers major protests and demonstrations",
      posted_by: "watcher_twitch",
      orientation: "horizontal",
      kind: "video",
      is_pinned: true
    },
    {
      source: "weather_cam_chicago",
      link: "https://www.youtube.com/watch?v=weather123",
      platform: "YouTube",
      status: "Live",
      city: "Chicago",
      state: "IL",
      title: "Chicago Weather Cam",
      notes: "Downtown Chicago weather camera",
      posted_by: "weatherfan",
      orientation: "horizontal",
      kind: "video"
    },
    {
      source: "seattle_traffic",
      link: "https://www.facebook.com/seattletraffic/live",
      platform: "Facebook",
      status: "Unknown",
      city: "Seattle",
      state: "WA",
      title: "I-5 Traffic Cam",
      notes: "Traffic monitoring stream",
      posted_by: "trafficwatch",
      orientation: "horizontal",
      kind: "web"
    },
    {
      source: "miami_beach_cam",
      link: "https://www.instagram.com/miamibeachcam/live",
      platform: "Instagram",
      status: "Live",
      city: "Miami",
      state: "FL",
      title: "Miami Beach Live",
      notes: "South Beach live camera",
      posted_by: "beachfan99",
      orientation: "vertical",
      kind: "video"
    }
  ]
  
  sample_streams.each do |stream_data|
    stream = Stream.create!(
      **stream_data,
      user: admin,
      last_checked_at: rand(1..24).hours.ago,
      last_live_at: stream_data[:status] == "Live" ? rand(1..6).hours.ago : rand(1..30).days.ago
    )
  end
  
  puts "Created #{sample_streams.count} sample streams for admin user"
  
  # Create sample streams for editor
  editor_streams = [
    {
      source: "boston_news",
      link: "https://www.tiktok.com/@boston_news/live",
      platform: "TikTok",
      status: "Live",
      city: "Boston",
      state: "MA",
      title: "Boston Breaking News",
      notes: "Local news coverage",
      posted_by: "editor_discord",
      orientation: "vertical",
      kind: "video"
    },
    {
      source: "denver_weather",
      link: "https://www.twitch.tv/denver_weather",
      platform: "Twitch",
      status: "Offline",
      city: "Denver",
      state: "CO",
      title: "Denver Weather Station",
      notes: "Mountain weather conditions",
      posted_by: "weatherbot",
      orientation: "horizontal",
      kind: "overlay"
    },
    {
      source: "phoenix_traffic",
      link: "https://example.com/phoenix-traffic",
      platform: "Other",
      status: "Unknown",
      city: "Phoenix",
      state: "AZ",
      title: "I-10 Traffic Monitor",
      notes: "Highway traffic cam",
      posted_by: "editor@example.com",
      orientation: "horizontal",
      kind: "web"
    }
  ]
  
  editor_streams.each do |stream_data|
    stream = Stream.create!(
      **stream_data,
      user: editor,
      last_checked_at: rand(1..48).hours.ago,
      last_live_at: stream_data[:status] == "Live" ? rand(1..12).hours.ago : nil
    )
  end
  
  puts "Created #{editor_streams.count} sample streams for editor user"
  
  # Create a stream for the default user
  Stream.create!(
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
    user: default_user,
    last_checked_at: 1.week.ago
  )
  
  puts "Created 1 sample stream for default user"
end

# Load feature flags
load Rails.root.join('db/seeds/feature_flags.rb')