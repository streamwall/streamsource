# Create test streamers
puts "Creating test streamers..."

admin = User.find_by(email: 'admin@example.com')

if admin
  # Create streamers
  streamers = [
    {
      name: "TechStreamer123",
      notes: "Popular tech content creator who streams coding tutorials",
      posted_by: "discord_admin"
    },
    {
      name: "NewsReporter",
      notes: "Independent journalist covering local events",
      posted_by: "admin_twitch"
    },
    {
      name: "CityWatcher",
      notes: "24/7 city surveillance streams",
      posted_by: "watcher_bot"
    }
  ]
  
  streamers.each do |streamer_data|
    streamer = Streamer.find_or_create_by!(name: streamer_data[:name]) do |s|
      s.notes = streamer_data[:notes]
      s.posted_by = streamer_data[:posted_by]
      s.user = admin
    end
    
    puts "Created streamer: #{streamer.name}"
    
    # Add platform accounts
    if streamer.name == "TechStreamer123"
      StreamerAccount.find_or_create_by!(
        streamer: streamer,
        platform: "TikTok",
        username: "techstreamer123"
      )
      StreamerAccount.find_or_create_by!(
        streamer: streamer,
        platform: "Twitch",
        username: "techstreamer123"
      )
    elsif streamer.name == "NewsReporter"
      StreamerAccount.find_or_create_by!(
        streamer: streamer,
        platform: "Facebook",
        username: "newsreporterlive"
      )
      StreamerAccount.find_or_create_by!(
        streamer: streamer,
        platform: "YouTube",
        username: "NewsReporterOfficial"
      )
    elsif streamer.name == "CityWatcher"
      StreamerAccount.find_or_create_by!(
        streamer: streamer,
        platform: "TikTok",
        username: "citywatcher_ny"
      )
    end
  end
  
  # Migrate existing streams to the first streamer as a test
  if Stream.where(streamer_id: nil).any?
    tech_streamer = Streamer.find_by(name: "TechStreamer123")
    if tech_streamer
      Stream.where(streamer_id: nil).limit(3).update_all(streamer_id: tech_streamer.id)
      puts "Assigned 3 streams to TechStreamer123"
    end
  end
  
  puts "Test streamers created successfully!"
else
  puts "Admin user not found. Please run db:seed first."
end