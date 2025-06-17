# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Only create default users in development and test environments
if Rails.env.development? || Rails.env.test?
  # Create default admin user
  admin = User.find_or_create_by!(email: 'admin@example.com') do |user|
    user.password = 'password123'
    user.role = 'admin'
    user.name = 'Admin User'
  end

  if admin.previously_new_record?
    puts "Admin user created: #{admin.email} (password: password123)"
  else
    puts "Admin user already exists: #{admin.email}"
  end

  # Create editor user
  editor = User.find_or_create_by!(email: 'editor@example.com') do |user|
    user.password = 'password123'
    user.role = 'editor'
    user.name = 'Editor User'
  end

  if editor.previously_new_record?
    puts "Editor user created: #{editor.email} (password: password123)"
  else
    puts "Editor user already exists: #{editor.email}"
  end

  # Create default user
  default_user = User.find_or_create_by!(email: 'user@example.com') do |user|
    user.password = 'password123'
    user.role = 'default'
    user.name = 'Default User'
  end

  if default_user.previously_new_record?
    puts "Default user created: #{default_user.email} (password: password123)"
  else
    puts "Default user already exists: #{default_user.email}"
  end
  
  puts "\n========================================"
  puts "Development Admin Login Credentials:"
  puts "Email: admin@example.com"
  puts "Password: password123"
  puts "========================================\n"
end

# Create sample streams for admin
if Stream.count.zero?
  5.times do |i|
    Stream.create!(
      name: "Admin Stream #{i + 1}",
      url: "https://example.com/stream#{i + 1}",
      user: admin,
      status: ['active', 'inactive'].sample,
      is_pinned: i < 2 # Pin first 2 streams
    )
  end
  
  puts "Created 5 sample streams for admin user"
  
  # Create sample streams for editor
  3.times do |i|
    Stream.create!(
      name: "Editor Stream #{i + 1}",
      url: "https://example.com/editor-stream#{i + 1}",
      user: editor,
      status: 'active'
    )
  end
  
  puts "Created 3 sample streams for editor user"
end

# Load feature flags
load Rails.root.join('db/seeds/feature_flags.rb')