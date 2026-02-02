# Entry points for auth-related rake tasks.
module AuthTasks
  module_function

  def test_all
    AuthTaskHttp.require_libs
    puts "=== Testing Authentication for All User Types ==="

    AuthTaskLogin.test_users.each { |user_info| AuthTaskLogin.test_login(user_info) }
  end

  def test_service_accounts
    puts "=== Testing Service Account Authentication ==="
    AuthTaskServiceAccounts.print_all
  end

  def test_rbac
    AuthTaskHttp.require_libs
    puts "=== Testing Role-Based Access Control ==="

    AuthTaskRBAC.test_all
  end

  def check_users
    puts "=== All Users in Database ==="
    AuthTaskUsers.print_counts
    AuthTaskUsers.print_details
  end
end

# Shared HTTP requirements for auth tasks.
module AuthTaskHttp
  module_function

  def require_libs
    require "net/http"
    require "uri"
    require "json"
  end
end

# Login helpers for auth tasks.
module AuthTaskLogin
  module_function

  LOGIN_URL = "http://localhost:3000/api/v1/login".freeze

  def test_users
    [
      { email: "admin@example.com", password: "Password123!", expected_role: "admin" },
      { email: "editor@example.com", password: "Password123!", expected_role: "editor" },
      { email: "user@example.com", password: "Password123!", expected_role: "default" },
    ]
  end

  def test_login(user_info)
    puts "\n--- Testing #{user_info[:expected_role]} (#{user_info[:email]}) ---"
    response = login_response(user_info)
    print_login_result(response)
  end

  def login_response(user_info)
    uri = URI(LOGIN_URL)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(user: user_info.slice(:email, :password))

    Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  end

  def print_login_result(response)
    if response.code == "200"
      data = JSON.parse(response.body)
      puts "✅ Login successful"
      puts "   Token: #{data['token'][0..50]}..."
      puts "   User role: #{data['user']['role']}"
    else
      puts "❌ Login failed: #{response.body}"
    end
  end
end

# Service account helpers for auth tasks.
module AuthTaskServiceAccounts
  module_function

  def print_all
    User.service_accounts.each { |account| print_service_account(account) }
  end

  def print_service_account(account)
    puts "\n--- #{account.email} ---"
    puts "Role: #{account.role}"
    puts "Service Account: #{account.is_service_account?}"

    decoded = decoded_token(account)
    days_left = (decoded["exp"] - Time.now.to_i) / 86_400.0

    puts "Token expires in: #{days_left} days"
    puts "Service account flag in token: #{decoded['service_account']}"
  end

  def decoded_token(account)
    token_payload = account.jwt_payload
    token = JWT.encode(token_payload, Rails.application.secret_key_base, "HS256")
    JWT.decode(token, nil, false)[0]
  end
end

# RBAC helpers for auth tasks.
module AuthTaskRBAC
  module_function

  RBAC_MATRIX = {
    "admin" => {
      "GET /api/v1/streams" => true,
      "POST /api/v1/streams" => true,
      "GET /api/v1/ignore_lists" => true,
    },
    "editor" => {
      "GET /api/v1/streams" => true,
      "POST /api/v1/streams" => true,
      "GET /api/v1/ignore_lists" => false,
    },
    "default" => {
      "GET /api/v1/streams" => true,
      "POST /api/v1/streams" => false,
      "GET /api/v1/ignore_lists" => false,
    },
  }.freeze

  def test_all
    rbac_test_users.each { |user| test_role_access(user) }
  end

  def rbac_test_users
    User.where(email: ["admin@example.com", "editor@example.com", "user@example.com"])
  end

  def test_role_access(user)
    puts "\n--- Testing #{user.role} role (#{user.email}) ---"
    token = jwt_token_for(user)

    RBAC_MATRIX.fetch(user.role, {}).each do |endpoint_desc, should_succeed|
      test_endpoint(token, endpoint_desc, should_succeed)
    end
  end

  def jwt_token_for(user)
    JWT.encode(user.jwt_payload, Rails.application.secret_key_base, "HS256")
  end

  def test_endpoint(token, endpoint_desc, should_succeed)
    method, path = endpoint_desc.split
    request = build_request(method, path, token)

    response = Net::HTTP.start(request.uri.host, request.uri.port) { |http| http.request(request) }
    success = response.code.to_i < 400

    if success == should_succeed
      puts "✅ #{endpoint_desc}: #{response.code} (as expected)"
    else
      puts "❌ #{endpoint_desc}: #{response.code} (expected #{should_succeed ? 'success' : 'failure'})"
    end
  end

  def build_request(method, path, token)
    uri = URI("http://localhost:3000#{path}")
    request = method == "POST" ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)

    request["Authorization"] = "Bearer #{token}"
    request["Content-Type"] = "application/json"

    if method == "POST" && path == "/api/v1/streams"
      request.body = JSON.generate(
        source: "test",
        link: "https://example.com/test",
        platform: "other",
        status: "unknown",
      )
    end

    request
  end
end

# User listing helpers for auth tasks.
module AuthTaskUsers
  module_function

  def print_counts
    puts "Total users: #{User.count}"
    puts "\nRegular users: #{User.regular_users.count}"
    puts "Service accounts: #{User.service_accounts.count}"
  end

  def print_details
    puts "\n--- User Details ---"

    User.order(:id).find_each do |user|
      puts "\nID: #{user.id}"
      puts "Email: #{user.email}"
      puts "Role: #{user.role}"
      puts "Service Account: #{user.is_service_account?}"
      puts "Created: #{user.created_at}"
    end
  end
end

namespace :auth do
  desc "Test API authentication for all user types"
  task test_all: :environment do
    AuthTasks.test_all
  end
end

namespace :auth do
  desc "Test service account authentication"
  task test_service_accounts: :environment do
    AuthTasks.test_service_accounts
  end
end

namespace :auth do
  desc "Test role-based access control"
  task test_rbac: :environment do
    AuthTasks.test_rbac
  end
end

namespace :auth do
  desc "Check all users and their authentication status"
  task check_users: :environment do
    AuthTasks.check_users
  end
end
