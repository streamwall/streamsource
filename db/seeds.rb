# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create default admin user
admin = User.find_or_create_by!(email: 'admin@example.com') do |user|
  user.password = 'Admin123!'
  user.role = 'admin'
end

puts "Admin user created: #{admin.email}"

# Create editor user
editor = User.find_or_create_by!(email: 'editor@example.com') do |user|
  user.password = 'Editor123!'
  user.role = 'editor'
end

puts "Editor user created: #{editor.email}"

# Create default user
default_user = User.find_or_create_by!(email: 'user@example.com') do |user|
  user.password = 'User123!'
  user.role = 'default'
end

puts "Default user created: #{default_user.email}"

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