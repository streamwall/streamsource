namespace :admin do
  desc "Create an admin user (usage: rake admin:create EMAIL=admin@example.com PASSWORD=SecurePass123!)"
  task create: :environment do
    email = ENV.fetch("EMAIL", nil)
    password = ENV.fetch("PASSWORD", nil)

    unless email && password
      puts "❌ Error: Please provide EMAIL and PASSWORD environment variables"
      puts "Usage: rake admin:create EMAIL=admin@example.com PASSWORD=SecurePass123!"
      exit 1
    end

    # Validate password complexity
    unless password.match?(ApplicationConstants::Password::COMPLEXITY_REGEX)
      puts "❌ Error: Password must include lowercase, uppercase, and number"
      exit 1
    end

    user = User.find_or_initialize_by(email: email)

    if user.new_record?
      user.password = password
      user.role = "admin"

      if user.save
        puts "✅ Admin user created successfully!"
        puts "   Email: #{user.email}"
        puts "   Role: #{user.role}"
        puts "   ID: #{user.id}"
      else
        puts "❌ Failed to create admin user:"
        user.errors.full_messages.each { |msg| puts "   - #{msg}" }
      end
    else
      puts "⚠️  User already exists: #{user.email}"

      if user.admin?
        puts "   Already an admin"
      else
        print "   Current role: #{user.role}. Promote to admin? (y/N): "
        if $stdin.gets.chomp.downcase == "y"
          user.update!(role: "admin")
          puts "   ✅ User promoted to admin"
        else
          puts "   ❌ User not modified"
        end
      end
    end
  end

  desc "List all admin users"
  task list: :environment do
    admins = User.admins

    if admins.any?
      puts "=== Admin Users (#{admins.count}) ==="
      admins.each do |admin|
        puts "\nEmail: #{admin.email}"
        puts "ID: #{admin.id}"
        puts "Created: #{admin.created_at}"
        puts "Service Account: #{admin.is_service_account? ? 'Yes' : 'No'}"
      end
    else
      puts "No admin users found."
    end
  end

  desc "Promote an existing user to admin (usage: rake admin:promote EMAIL=user@example.com)"
  task promote: :environment do
    email = ENV.fetch("EMAIL", nil)

    unless email
      puts "❌ Error: Please provide EMAIL environment variable"
      puts "Usage: rake admin:promote EMAIL=user@example.com"
      exit 1
    end

    user = User.find_by(email: email)

    if user
      if user.admin?
        puts "⚠️  User #{email} is already an admin"
      else
        previous_role = user.role
        user.update!(role: "admin")
        puts "✅ User promoted to admin"
        puts "   Email: #{user.email}"
        puts "   Previous role: #{previous_role}"
        puts "   New role: #{user.role}"
      end
    else
      puts "❌ User not found: #{email}"
    end
  end

  desc "Demote an admin to a different role (usage: rake admin:demote EMAIL=admin@example.com ROLE=editor)"
  task demote: :environment do
    email = ENV.fetch("EMAIL", nil)
    new_role = ENV["ROLE"] || "default"

    unless email
      puts "❌ Error: Please provide EMAIL environment variable"
      puts "Usage: rake admin:demote EMAIL=admin@example.com ROLE=editor"
      exit 1
    end

    unless %w[default editor].include?(new_role)
      puts "❌ Error: ROLE must be 'default' or 'editor'"
      exit 1
    end

    user = User.find_by(email: email)

    if user
      if user.admin?
        # Check if this is the last admin
        if User.admins.one?
          puts "❌ Cannot demote the last admin user"
          exit 1
        end

        user.update!(role: new_role)
        puts "✅ Admin demoted"
        puts "   Email: #{user.email}"
        puts "   Previous role: admin"
        puts "   New role: #{user.role}"
      else
        puts "⚠️  User #{email} is not an admin (current role: #{user.role})"
      end
    else
      puts "❌ User not found: #{email}"
    end
  end
end
