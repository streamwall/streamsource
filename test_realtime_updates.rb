#!/usr/bin/env ruby
# This script demonstrates real-time stream updates via the API affecting the web UI

puts "=== Real-time Stream Updates Test ==="
puts "This test will create a stream via the API and demonstrate that it appears"
puts "in real-time on the admin web interface without page refresh."
puts
puts "Prerequisites:"
puts "1. Start the Rails server: docker compose exec web bin/rails server -b 0.0.0.0"
puts "2. Open the admin interface in a browser: http://localhost:3000/admin/streams"
puts "3. Log in to the admin interface"
puts "4. Keep the streams page open while running this script"
puts
puts "Steps this script will perform:"
puts "1. Create a new stream via the API"
puts "2. The stream should appear instantly in the web UI"
puts "3. Update the stream status to 'Live'"
puts "4. The stream should update instantly in the web UI"
puts "5. Delete the stream"
puts "6. The stream should disappear instantly from the web UI"
puts
puts "Press Enter to continue..."
gets

require "net/http"
require "json"
require "uri"

# API configuration
API_BASE_URL = "http://localhost:3000/api/v1".freeze
API_EMAIL = "test@example.com".freeze
API_PASSWORD = "Password123!".freeze

# Helper method to make API requests
def api_request(method, path, body = nil, token = nil)
  puts "Making #{method.upcase} request to #{API_BASE_URL}#{path} with body: #{body.inspect}" if body
  puts "Using token: #{token}" if token

  uri = URI("#{API_BASE_URL}#{path}")

  request = case method
            when :post
              Net::HTTP::Post.new(uri)
            when :put
              Net::HTTP::Put.new(uri)
            when :delete
              Net::HTTP::Delete.new(uri)
            else
              Net::HTTP::Get.new(uri)
            end

  puts "Request URI: #{uri}" if method == :get
  puts "Request body: #{body.inspect}" if body

  request["Content-Type"] = "application/json"
  request["Authorization"] = "Bearer #{token}" if token
  request.body = body.to_json if body

  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end

  puts "Response status: #{response.code} #{response.message}"
  puts "Response body: #{response.body}" if response.body.present?

  body = JSON.parse(response.body) if response.body.present?
  puts "Parsed response: #{body.inspect}" if body
  body
end

# Step 1: Login to get JWT token
puts "\n1. Logging in to API..."
login_response = api_request(:post, "/users/login", {
                               email: API_EMAIL,
                               password: API_PASSWORD,
                             })

if login_response && login_response["token"]
  token = login_response["token"]
  puts "   ✓ Login successful"
else
  puts "   ✗ Login failed. Make sure the test user exists."
  puts "   Run: docker compose exec web bin/rails console"
  puts "   Then: User.create!(email: '#{API_EMAIL}', password: '#{API_PASSWORD}', role: 'admin')"
  exit 1
end

# Step 2: Create a stream
puts "\n2. Creating a new stream via API..."
stream_data = {
  link: "https://example.com/stream-#{Time.now.to_i}",
  source: "Real-time Test Stream #{Time.zone.now.strftime('%H:%M:%S')}",
  platform: "TikTok",
  status: "Unknown",
  kind: "video",
}

create_response = api_request(:post, "/streams", stream_data, token)

if create_response && create_response["stream"]
  stream = create_response["stream"]
  stream_id = stream["id"]
  puts "   ✓ Stream created (ID: #{stream_id})"
  puts "   → Check your browser - the stream should appear at the top of the list!"
else
  puts "   ✗ Failed to create stream"
  exit 1
end

# Wait a moment
puts "\n   Waiting 3 seconds..."
sleep 3

# Step 3: Update the stream to Live status
puts "\n3. Updating stream status to 'Live'..."
update_response = api_request(:put, "/streams/#{stream_id}", {
                                status: "Live",
                                title: "Now Broadcasting Live!",
                              }, token)

if update_response && update_response["data"]
  puts "   ✓ Stream updated to Live status"
  puts "   → Check your browser - the stream status should change to a green 'Live' badge!"
else
  puts "   ✗ Failed to update stream"
end

# Wait a moment
puts "\n   Waiting 3 seconds..."
sleep 3

# Step 4: Update again with different platform
puts "\n4. Changing platform to 'YouTube'..."
update_response = api_request(:put, "/streams/#{stream_id}", {
                                platform: "YouTube",
                              }, token)

if update_response && update_response["data"]
  puts "   ✓ Platform updated"
  puts "   → Check your browser - the platform badge should change color!"
else
  puts "   ✗ Failed to update platform"
end

# Wait before deletion
puts "\n   Waiting 3 seconds before deletion..."
sleep 3

# Step 5: Delete the stream
puts "\n5. Deleting the stream..."
api_request(:delete, "/streams/#{stream_id}", nil, token)

puts "   ✓ Stream deleted"
puts "   → Check your browser - the stream should disappear from the list!"

puts "\n=== Test Complete ==="
puts "If you saw the stream appear, update, and disappear in real-time without"
puts "refreshing the page, then Hotwire broadcasting is working correctly!"
puts
puts "Note: If updates didn't appear in real-time, make sure:"
puts "1. ActionCable/Redis is running (check docker compose logs)"
puts "2. You're viewing the admin streams page (/admin/streams)"
puts "3. JavaScript is enabled in your browser"
