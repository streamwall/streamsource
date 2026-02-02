# Create test streamers
Rails.logger.debug "Creating test streamers..."

admin = User.find_by(email: "admin@example.com")

def streamer_seed_data
  [
    {
      name: "TechStreamer123",
      notes: "Popular tech content creator who streams coding tutorials",
      posted_by: "discord_admin",
    },
    {
      name: "NewsReporter",
      notes: "Independent journalist covering local events",
      posted_by: "admin_twitch",
    },
    {
      name: "CityWatcher",
      notes: "24/7 city surveillance streams",
      posted_by: "watcher_bot",
    },
  ]
end

def streamer_accounts_for(name)
  case name
  when "TechStreamer123"
    [
      { platform: "TikTok", username: "techstreamer123" },
      { platform: "Twitch", username: "techstreamer123" },
    ]
  when "NewsReporter"
    [
      { platform: "Facebook", username: "newsreporterlive" },
      { platform: "YouTube", username: "NewsReporterOfficial" },
    ]
  when "CityWatcher"
    [
      { platform: "TikTok", username: "citywatcher_ny" },
    ]
  else
    []
  end
end

def seed_streamer_accounts(streamer)
  streamer_accounts_for(streamer.name).each do |account|
    StreamerAccount.find_or_create_by!(account.merge(streamer: streamer))
  end
end

def assign_test_streams(streamer)
  Stream.where(streamer_id: nil).limit(3).find_each do |stream|
    stream.update!(streamer: streamer)
  end

  Rails.logger.debug { "Assigned 3 streams to #{streamer.name}" }
end

if admin
  streamer_seed_data.each do |streamer_data|
    streamer = Streamer.find_or_create_by!(name: streamer_data[:name]) do |record|
      record.notes = streamer_data[:notes]
      record.posted_by = streamer_data[:posted_by]
      record.user = admin
    end

    Rails.logger.debug { "Created streamer: #{streamer.name}" }
    seed_streamer_accounts(streamer)
  end

  tech_streamer = Streamer.find_by(name: "TechStreamer123")
  assign_test_streams(tech_streamer) if tech_streamer && Stream.where(streamer_id: nil).any?

  Rails.logger.debug { "Test streamers created successfully!" }
else
  Rails.logger.debug { "Admin user not found. Please run db:seed first." }
end
