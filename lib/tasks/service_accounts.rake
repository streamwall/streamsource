namespace :service_accounts do
  desc "Create service accounts for external services"
  task setup: :environment do
    # Define service accounts with secure passwords
    service_accounts = [
      {
        email: 'livestream-monitor@streamsource.local',
        password: "Monitor#{SecureRandom.hex(16)}1",
        description: 'livestream-link-monitor service'
      },
      {
        email: 'livesheet-updater@streamsource.local',
        password: "Updater#{SecureRandom.hex(16)}2",
        description: 'livesheet-updater service'
      }
    ]
    
    puts "=== Creating Service Accounts ==="
    
    service_accounts.each do |account_info|
      user = User.find_or_initialize_by(email: account_info[:email])
      
      if user.new_record?
        user.password = account_info[:password]
        user.role = 'editor'
        user.is_service_account = true
        
        if user.save
          puts "\n✅ Created service account for #{account_info[:description]}"
          puts "   Email: #{user.email}"
          puts "   Password: #{account_info[:password]}"
          puts "   Role: #{user.role}"
          puts "   ID: #{user.id}"
        else
          puts "\n❌ Failed to create #{account_info[:email]}: #{user.errors.full_messages.join(', ')}"
        end
      else
        puts "\n✓ Service account already exists: #{user.email} (ID: #{user.id})"
      end
    end
    
    puts "\n=== Service Account Configuration ==="
    puts "- 30-day JWT token expiration"
    puts "- Editor permissions (can create/update streams)"
    puts "- Passwords shown above for initial setup only"
    puts "\nAdd these to your service environment variables:"
    puts "STREAMSOURCE_EMAIL=<email shown above>"
    puts "STREAMSOURCE_PASSWORD=<password shown above>"
  end

  desc "Generate login tokens for service accounts"
  task generate_tokens: :environment do
    User.service_accounts.each do |account|
      puts "\n=== #{account.email} ==="
      puts "Service Account ID: #{account.id}"
      puts "Role: #{account.role}"
      puts "Token expires in: 30 days"
      
      # Generate a sample JWT token (this would normally be done via login)
      token_payload = account.jwt_payload
      puts "Sample JWT payload:"
      puts JSON.pretty_generate(token_payload)
    end
    
    puts "\nTo get actual tokens, make POST requests to /api/v1/login with service account credentials"
  end

  desc "List all service accounts"
  task list: :environment do
    puts "Service Accounts:"
    puts "=================="
    
    User.service_accounts.each do |account|
      puts "Email: #{account.email}"
      puts "Role: #{account.role}"
      puts "Created: #{account.created_at}"
      puts "ID: #{account.id}"
      puts "---"
    end
  end
end