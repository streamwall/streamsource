# Helpers for service account rake tasks.
module ServiceAccountTasks
  module_function

  def setup
    puts "=== Creating Service Accounts ==="

    service_accounts_data.each { |account_info| create_service_account(account_info) }
    print_setup_notes
  end

  def generate_tokens
    User.service_accounts.each { |account| print_service_token(account) }

    puts "\nTo get actual tokens, make POST requests to /api/v1/login with service account credentials"
  end

  def list
    puts "Service Accounts:"
    puts "=================="

    User.service_accounts.each { |account| print_service_account(account) }
  end

  def service_accounts_data
    [
      {
        email: "livestream-monitor@streamsource.local",
        password: "Monitor#{SecureRandom.hex(16)}1",
        description: "livestream-link-monitor service",
      },
      {
        email: "livesheet-updater@streamsource.local",
        password: "Updater#{SecureRandom.hex(16)}2",
        description: "livesheet-updater service",
      },
    ]
  end

  def create_service_account(account_info)
    user = User.find_or_initialize_by(email: account_info[:email])

    return print_existing_account(user) unless user.new_record?

    configure_new_account(user, account_info)
    save_service_account(user, account_info)
  end

  def configure_new_account(user, account_info)
    user.password = account_info[:password]
    user.role = "editor"
    user.is_service_account = true
  end

  def save_service_account(user, account_info)
    if user.save
      print_created_account(user, account_info)
    else
      print_failed_account(user, account_info)
    end
  end

  def print_created_account(user, account_info)
    puts "\n✅ Created service account for #{account_info[:description]}"
    puts "   Email: #{user.email}"
    puts "   Password: #{account_info[:password]}"
    puts "   Role: #{user.role}"
    puts "   ID: #{user.id}"
  end

  def print_failed_account(user, account_info)
    message = user.errors.full_messages.join(", ")
    puts "\n❌ Failed to create #{account_info[:email]}: #{message}"
  end

  def print_existing_account(user)
    puts "\n✓ Service account already exists: #{user.email} (ID: #{user.id})"
  end

  def print_setup_notes
    puts "\n=== Service Account Configuration ==="
    puts "- 30-day JWT token expiration"
    puts "- Editor permissions (can create/update streams)"
    puts "- Passwords shown above for initial setup only"
    puts "\nAdd these to your service environment variables:"
    puts "STREAMSOURCE_EMAIL=<email shown above>"
    puts "STREAMSOURCE_PASSWORD=<password shown above>"
  end

  def print_service_token(account)
    puts "\n=== #{account.email} ==="
    puts "Service Account ID: #{account.id}"
    puts "Role: #{account.role}"
    puts "Token expires in: 30 days"
    puts "Sample JWT payload:"
    puts JSON.pretty_generate(account.jwt_payload)
  end

  def print_service_account(account)
    puts "Email: #{account.email}"
    puts "Role: #{account.role}"
    puts "Created: #{account.created_at}"
    puts "ID: #{account.id}"
    puts "---"
  end
end

namespace :service_accounts do
  desc "Create service accounts for external services"
  task setup: :environment do
    ServiceAccountTasks.setup
  end
end

namespace :service_accounts do
  desc "Generate login tokens for service accounts"
  task generate_tokens: :environment do
    ServiceAccountTasks.generate_tokens
  end
end

namespace :service_accounts do
  desc "List all service accounts"
  task list: :environment do
    ServiceAccountTasks.list
  end
end
