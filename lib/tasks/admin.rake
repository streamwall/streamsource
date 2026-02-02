# Helper methods for admin task output and workflows.
module AdminTaskHelpers
  module_function

  def persist_admin_create(user)
    if user.save
      puts "✅ Admin user created successfully!"
      puts "   Email: #{user.email}"
      puts "   Role: #{user.role}"
      puts "   ID: #{user.id}"
    else
      puts "❌ Failed to create admin user:"
      user.errors.full_messages.each { |msg| puts "   - #{msg}" }
    end
  end

  def handle_existing_admin(user)
    puts "⚠️  User already exists: #{user.email}"

    if user.admin?
      puts "   Already an admin"
    else
      prompt_for_promotion(user)
    end
  end

  def prompt_for_promotion(user)
    print "   Current role: #{user.role}. Promote to admin? (y/N): "
    if $stdin.gets.chomp.downcase == "y"
      user.update!(role: "admin")
      puts "   ✅ User promoted to admin"
    else
      puts "   ❌ User not modified"
    end
  end

  def print_admin(admin)
    puts "\nEmail: #{admin.email}"
    puts "ID: #{admin.id}"
    puts "Created: #{admin.created_at}"
    puts "Service Account: #{admin.is_service_account? ? 'Yes' : 'No'}"
  end

  def handle_promotion(user)
    if user.admin?
      puts "⚠️  User #{user.email} is already an admin"
      return
    end

    previous_role = user.role
    user.update!(role: "admin")
    puts "✅ User promoted to admin"
    puts "   Email: #{user.email}"
    puts "   Previous role: #{previous_role}"
    puts "   New role: #{user.role}"
  end

  def handle_demotion(user, new_role)
    unless user.admin?
      puts "⚠️  User #{user.email} is not an admin (current role: #{user.role})"
      return
    end

    if User.admins.one?
      puts "❌ Cannot demote the last admin user"
      exit 1
    end

    user.update!(role: new_role)
    puts "✅ Admin demoted"
    puts "   Email: #{user.email}"
    puts "   Previous role: admin"
    puts "   New role: #{user.role}"
  end
end

# Admin user management tasks.
module AdminTasks
  module_function

  def create_admin!(email:, password:)
    validate_create_inputs(email, password)

    user = User.find_or_initialize_by(email: email)
    return AdminTaskHelpers.handle_existing_admin(user) unless user.new_record?

    assign_new_admin(user, password)
    AdminTaskHelpers.persist_admin_create(user)
  end

  def list_admins
    admins = User.admins

    if admins.any?
      puts "=== Admin Users (#{admins.count}) ==="
      admins.each { |admin| AdminTaskHelpers.print_admin(admin) }
    else
      puts "No admin users found."
    end
  end

  def promote_admin!(email:)
    validate_email_input(email, "promote")

    user = User.find_by(email: email)
    if user
      AdminTaskHelpers.handle_promotion(user)
    else
      puts "❌ User not found: #{email}"
    end
  end

  def demote_admin!(email:, new_role:)
    validate_email_input(email, "demote")
    validate_role_input(new_role)

    user = User.find_by(email: email)
    if user
      AdminTaskHelpers.handle_demotion(user, new_role)
    else
      puts "❌ User not found: #{email}"
    end
  end

  def validate_create_inputs(email, password)
    unless email && password
      puts "❌ Error: Please provide EMAIL and PASSWORD environment variables"
      puts "Usage: rake admin:create EMAIL=admin@example.com PASSWORD=SecurePass123!"
      exit 1
    end

    return if password.match?(ApplicationConstants::Password::COMPLEXITY_REGEX)

    puts "❌ Error: Password must include lowercase, uppercase, and number"
    exit 1
  end

  def validate_email_input(email, action)
    return if email

    puts "❌ Error: Please provide EMAIL environment variable"
    puts "Usage: rake admin:#{action} EMAIL=user@example.com"
    exit 1
  end

  def validate_role_input(new_role)
    return if %w[default editor].include?(new_role)

    puts "❌ Error: ROLE must be 'default' or 'editor'"
    exit 1
  end

  def assign_new_admin(user, password)
    user.password = password
    user.role = "admin"
  end
end

namespace :admin do
  desc "Create an admin user (usage: rake admin:create EMAIL=admin@example.com PASSWORD=SecurePass123!)"
  task create: :environment do
    AdminTasks.create_admin!(email: ENV.fetch("EMAIL", nil), password: ENV.fetch("PASSWORD", nil))
  end
end

namespace :admin do
  desc "List all admin users"
  task list: :environment do
    AdminTasks.list_admins
  end
end

namespace :admin do
  desc "Promote an existing user to admin (usage: rake admin:promote EMAIL=user@example.com)"
  task promote: :environment do
    AdminTasks.promote_admin!(email: ENV.fetch("EMAIL", nil))
  end
end

namespace :admin do
  desc "Demote an admin to a different role (usage: rake admin:demote EMAIL=admin@example.com ROLE=editor)"
  task demote: :environment do
    AdminTasks.demote_admin!(email: ENV.fetch("EMAIL", nil), new_role: ENV["ROLE"] || "default")
  end
end
