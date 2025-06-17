# RSpec Shared Test Helpers

This directory contains shared test helpers, contexts, and examples to make our tests DRYer and more maintainable.

## Overview

### Helper Modules

#### `JwtHelpers` (jwt_helpers.rb)
Provides JWT token generation and authentication helpers.

```ruby
# Generate JWT token
token = generate_jwt_token(user)

# Generate auth headers
headers = auth_headers(user)

# Generate expired headers
headers = expired_auth_headers(user)

# Generate invalid headers
headers = invalid_auth_headers
```

#### `AdminHelpers` (admin_helpers.rb)
Helpers for admin interface testing.

```ruby
# Setup admin authentication
setup_admin_auth(admin_user)

# Sign in admin user
sign_in_admin(admin_user)

# Assert successful admin page
expect_admin_page_success

# Assert admin redirect
expect_admin_redirect_to(admin_users_path)

# Check content in admin views
expect_admin_page_to_include("User Name", "user@example.com")
expect_admin_page_not_to_include("Deleted User")
```

#### `ApiHelpers` (api_helpers.rb)
Helpers for API testing.

```ruby
# Parse JSON response
data = json_response

# Expect successful JSON response
expect_json_success

# Expect created response
expect_json_created

# Expect JSON error
expect_json_error(:forbidden)

# Expect paginated response
expect_paginated_response(expected_count: 10, page: 1, per_page: 25)

# Make authenticated API requests
api_get("/api/v1/streams", user: current_user)
api_post("/api/v1/streams", params: stream_params, user: current_user)
```

#### `TestHelpers` (test_helpers.rb)
General testing utilities.

```ruby
# Test filtering
test_filter(streams_path, :status, 'live', 3)

# Test pagination
test_pagination(streams_path, total_items: 50, per_page: 25)

# Test sorting
test_sorting(streams_path, :created_at, streams) { |s| s.created_at }

# Test validation errors
test_validation_errors(:post, :create, invalid_params, ["Name can't be blank"])

# Test value changes
expect_to_change_value(stream, :is_pinned, from: false, to: true) do
  patch pin_stream_path(stream)
end

# Test that value doesn't change
expect_not_to_change_value(stream, :source) do
  patch update_stream_path(stream), params: invalid_params
end
```

### Shared Contexts

#### Authentication Contexts (shared_contexts/authentication.rb)

```ruby
# Admin authentication
include_context "with admin authentication"

# Editor authentication
include_context "with editor authentication"

# Default user authentication
include_context "with default user authentication"

# Multiple user roles
include_context "with different user roles"
# Provides: admin_user, editor_user, default_user, and their headers

# JWT variations
include_context "with JWT variations"
# Provides: valid_headers, expired_headers, invalid_headers, etc.

# Sample resources
include_context "with sample resources"
# Provides: user_stream, pinned_stream, offline_stream, etc.
```

### Shared Examples

#### Authorization Examples (shared_examples/authorization.rb)

```ruby
# Test that authentication is required
it_behaves_like "requires authentication", :get, :index

# Test that admin role is required
it_behaves_like "requires admin role", :post, :create, { name: "Test" }

# Test that editor role is required
it_behaves_like "requires editor role", :post, :create

# Test that admin can access
it_behaves_like "allows admin access", :get, :show, { id: 1 }

# Test full CRUD authorization for admin interface
it_behaves_like "admin crud authorization"

# Test full CRUD authorization for API
it_behaves_like "api crud authorization", :stream
```

#### CRUD Operation Examples (shared_examples/crud_operations.rb)

```ruby
# Test successful index action
it_behaves_like "successful index action", resource: :stream

# Test successful show action
it_behaves_like "successful show action", resource: :stream

# Test successful create action
it_behaves_like "successful create action", 
  resource: :stream,
  valid_params: { name: "Test" },
  invalid_params: { name: "" }

# Test successful update action
it_behaves_like "successful update action",
  resource: :stream,
  update_params: { name: "Updated" }

# Test successful destroy action
it_behaves_like "successful destroy action", resource: :stream

# Test full admin CRUD actions
it_behaves_like "admin crud actions", :stream,
  display_attribute: :name,
  show_attributes: [:name, :link, :status],
  valid_params: { name: "Test", link: "https://example.com" },
  invalid_params: { name: "", link: "" }
```

## Usage Examples

### Refactoring an Admin Request Spec

Before:
```ruby
RSpec.describe "Admin::Streams", type: :request do
  let(:admin_user) { create(:user, :admin) }
  
  before do
    allow_any_instance_of(Admin::BaseController).to receive(:current_admin_user).and_return(admin_user)
    allow_any_instance_of(Admin::BaseController).to receive(:authenticate_admin!).and_return(true)
  end
  
  describe "GET /admin/streams" do
    it "returns successful response" do
      get admin_streams_path
      expect(response).to have_http_status(:success)
    end
  end
end
```

After:
```ruby
RSpec.describe "Admin::Streams", type: :request do
  include_context "with admin authentication"
  
  it_behaves_like "admin crud authorization"
  
  describe "GET /admin/streams" do
    it "returns successful response" do
      get admin_streams_path
      expect_admin_page_success
    end
  end
end
```

### Refactoring an API Controller Spec

Before:
```ruby
RSpec.describe Api::V1::StreamsController, type: :controller do
  let(:user) { create(:user) }
  
  describe 'GET #index' do
    context 'without authentication' do
      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
    
    context 'with authentication' do
      before { request.headers.merge!(auth_headers(user)) }
      
      it 'returns success' do
        get :index
        expect(response).to have_http_status(:success)
      end
    end
  end
end
```

After:
```ruby
RSpec.describe Api::V1::StreamsController, type: :controller do
  include_context "with different user roles"
  
  it_behaves_like "api crud authorization", :stream
  
  describe 'GET #index' do
    it_behaves_like "requires authentication", :get, :index
    
    context 'with authentication' do
      before { request.headers.merge!(default_headers) }
      
      it_behaves_like "successful index action", resource: :stream
    end
  end
end
```

### Testing Authorization Patterns

```ruby
RSpec.describe Api::V1::StreamsController, type: :controller do
  include_context "with different user roles"
  
  describe 'POST #create' do
    let(:valid_params) { { source: 'Test', link: 'https://example.com' } }
    
    it_behaves_like "requires authentication", :post, :create
    it_behaves_like "requires editor role", :post, :create, valid_params
    it_behaves_like "allows admin access", :post, :create, valid_params
  end
end
```

### Testing Pagination and Filtering

```ruby
RSpec.describe "Api::V1::Streams", type: :request do
  include_context "with editor authentication"
  
  describe "GET /api/v1/streams" do
    let!(:streams) { create_list(:stream, 30, user: editor_user) }
    
    it "paginates results" do
      test_pagination("/api/v1/streams", 30)
    end
    
    it "filters by status" do
      live_streams = create_list(:stream, 5, status: 'live')
      offline_streams = create_list(:stream, 3, status: 'offline')
      
      test_filter("/api/v1/streams", :status, 'live', 5)
    end
  end
end
```

## Best Practices

1. **Use shared contexts** for common setup like authentication
2. **Use shared examples** for repeated test patterns
3. **Keep shared examples focused** - one behavior per example
4. **Name shared examples clearly** - describe what they test
5. **Document required variables** in shared examples
6. **Prefer composition** - combine multiple shared examples/contexts
7. **Keep helpers simple** - complex logic belongs in the tests

## Adding New Helpers

When adding new shared helpers:

1. Place them in the appropriate file or create a new one
2. Include clear documentation and examples
3. Make them composable with existing helpers
4. Test the helpers themselves if they contain complex logic
5. Update this README with usage examples