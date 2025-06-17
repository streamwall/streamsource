module ApiHelpers
  # Parse JSON response body
  def json_response
    JSON.parse(response.body)
  end
  
  # Expect successful JSON response
  def expect_json_success
    expect(response).to have_http_status(:success)
    expect(response.content_type).to include('application/json')
  end
  
  # Expect created JSON response
  def expect_json_created
    expect(response).to have_http_status(:created)
    expect(response.content_type).to include('application/json')
  end
  
  # Expect JSON error response
  def expect_json_error(status)
    expect(response).to have_http_status(status)
    expect(response.content_type).to include('application/json')
    expect(json_response).to have_key('error')
  end
  
  # Expect paginated response
  def expect_paginated_response(expected_count: nil, page: 1, per_page: 25)
    expect_json_success
    expect(json_response).to have_key('meta')
    
    meta = json_response['meta']
    expect(meta['current_page']).to eq(page)
    expect(meta['per_page']).to eq(per_page)
    expect(meta).to have_key('total_pages')
    expect(meta).to have_key('total_count')
    
    if expected_count
      expect(json_response['data'].count).to eq(expected_count)
    end
  end
  
  # Helper to build common filter params
  def filter_params(filters = {})
    {
      status: filters[:status],
      platform: filters[:platform],
      user_id: filters[:user_id],
      is_pinned: filters[:is_pinned],
      page: filters[:page] || 1,
      per_page: filters[:per_page] || 25
    }.compact
  end
  
  # Assert API error response format
  def expect_api_error_format(message = nil)
    expect(json_response).to have_key('error')
    expect(json_response['error']).to eq(message) if message
  end
  
  # Assert successful API response format
  def expect_api_success_format
    expect(response).to be_successful
    # Most API responses wrap data in a root key
    expect(json_response).to be_a(Hash)
  end
  
  # Helper for making authenticated API requests
  def api_get(path, params: {}, headers: {}, user: nil)
    headers = auth_headers(user) if user
    get path, params: params, headers: headers
  end
  
  def api_post(path, params: {}, headers: {}, user: nil)
    headers = auth_headers(user) if user
    post path, params: params, headers: headers
  end
  
  def api_patch(path, params: {}, headers: {}, user: nil)
    headers = auth_headers(user) if user
    patch path, params: params, headers: headers
  end
  
  def api_delete(path, params: {}, headers: {}, user: nil)
    headers = auth_headers(user) if user
    delete path, params: params, headers: headers
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
  config.include ApiHelpers, type: :controller
end