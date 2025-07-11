namespace :auth do
  desc "Test API authentication for all user types"
  task test_all: :environment do
    require 'net/http'
    require 'uri'
    require 'json'

    puts "=== Testing Authentication for All User Types ==="
    
    test_users = [
      { email: 'admin@example.com', password: 'Password123!', expected_role: 'admin' },
      { email: 'editor@example.com', password: 'Password123!', expected_role: 'editor' },
      { email: 'user@example.com', password: 'Password123!', expected_role: 'default' }
    ]

    test_users.each do |user_info|
      puts "\n--- Testing #{user_info[:expected_role]} (#{user_info[:email]}) ---"
      
      uri = URI('http://localhost:3000/api/v1/login')
      http = Net::HTTP.new(uri.host, uri.port)
      
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = JSON.generate({ user: user_info.slice(:email, :password) })
      
      response = http.request(request)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        puts "✅ Login successful"
        puts "   Token: #{data['token'][0..50]}..."
        puts "   User role: #{data['user']['role']}"
      else
        puts "❌ Login failed: #{response.body}"
      end
    end
  end

  desc "Test service account authentication"
  task test_service_accounts: :environment do
    puts "=== Testing Service Account Authentication ==="
    
    User.service_accounts.each do |account|
      puts "\n--- #{account.email} ---"
      puts "Role: #{account.role}"
      puts "Service Account: #{account.is_service_account?}"
      
      # Generate a sample JWT to verify token structure
      token_payload = account.jwt_payload
      token = JWT.encode(token_payload, Rails.application.secret_key_base, 'HS256')
      decoded = JWT.decode(token, nil, false)[0]
      
      puts "Token expires in: #{(decoded['exp'] - Time.now.to_i) / 86400.0} days"
      puts "Service account flag in token: #{decoded['service_account']}"
    end
  end

  desc "Test role-based access control"
  task test_rbac: :environment do
    require 'net/http'
    require 'uri'
    require 'json'

    puts "=== Testing Role-Based Access Control ==="
    
    # Test endpoints and expected access
    test_matrix = {
      'admin' => { 
        'GET /api/v1/streams' => true,
        'POST /api/v1/streams' => true,
        'GET /api/v1/ignore_lists' => true
      },
      'editor' => {
        'GET /api/v1/streams' => true,
        'POST /api/v1/streams' => true,
        'GET /api/v1/ignore_lists' => false  # Assuming admin-only
      },
      'default' => {
        'GET /api/v1/streams' => true,
        'POST /api/v1/streams' => false,
        'GET /api/v1/ignore_lists' => false
      }
    }

    User.where(email: ['admin@example.com', 'editor@example.com', 'user@example.com']).each do |user|
      puts "\n--- Testing #{user.role} role (#{user.email}) ---"
      
      # Generate token for user
      token_payload = user.jwt_payload
      token = JWT.encode(token_payload, Rails.application.secret_key_base, 'HS256')
      
      test_matrix[user.role].each do |endpoint_desc, should_succeed|
        method, path = endpoint_desc.split(' ')
        
        uri = URI("http://localhost:3000#{path}")
        http = Net::HTTP.new(uri.host, uri.port)
        
        request = case method
        when 'GET' then Net::HTTP::Get.new(uri)
        when 'POST' then Net::HTTP::Post.new(uri)
        end
        
        request['Authorization'] = "Bearer #{token}"
        request['Content-Type'] = 'application/json'
        
        if method == 'POST' && path == '/api/v1/streams'
          request.body = JSON.generate({
            source: 'test',
            link: 'https://example.com/test',
            platform: 'other',
            status: 'unknown'
          })
        end
        
        response = http.request(request)
        success = response.code.to_i < 400
        
        if success == should_succeed
          puts "✅ #{endpoint_desc}: #{response.code} (as expected)"
        else
          puts "❌ #{endpoint_desc}: #{response.code} (expected #{should_succeed ? 'success' : 'failure'})"
        end
      end
    end
  end

  desc "Check all users and their authentication status"
  task check_users: :environment do
    puts "=== All Users in Database ==="
    puts "Total users: #{User.count}"
    puts "\nRegular users: #{User.regular_users.count}"
    puts "Service accounts: #{User.service_accounts.count}"
    
    puts "\n--- User Details ---"
    User.order(:id).each do |user|
      puts "\nID: #{user.id}"
      puts "Email: #{user.email}"
      puts "Role: #{user.role}"
      puts "Service Account: #{user.is_service_account?}"
      puts "Created: #{user.created_at}"
    end
  end
end