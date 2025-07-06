module TestHelpers
  # Create multiple resources with different attributes
  def create_resources_with_attributes(factory, count, attributes_list)
    attributes_list.take(count).map.with_index do |attrs, _i|
      create(factory, attrs)
    end
  end

  # Helper to test filtering
  def test_filter(path, filter_param, filter_value, expected_count)
    get path, params: { filter_param => filter_value }
    expect_json_success

    results = block_given? ? yield(json_response) : json_response["data"]
    expect(results.count).to eq(expected_count)
  end

  # Helper to test pagination
  def test_pagination(path, total_items, per_page = 25)
    # First page
    get path, params: { page: 1, per_page: per_page }
    expect_paginated_response(page: 1, per_page: per_page)

    first_page_count = [total_items, per_page].min
    expect(json_response["data"].count).to eq(first_page_count)

    # Test second page if there are more items
    return unless total_items > per_page

    get path, params: { page: 2, per_page: per_page }
    expect_paginated_response(page: 2, per_page: per_page)

    second_page_count = [total_items - per_page, per_page].min
    expect(json_response["data"].count).to eq(second_page_count)
  end

  # Helper to test sorting
  def test_sorting(path, sort_param, resources, &)
    get path, params: { sort: sort_param }
    expect_json_success

    results = json_response["data"]
    sorted_ids = results.pluck("id")
    expected_ids = resources.sort_by(&).map(&:id)

    expect(sorted_ids).to eq(expected_ids)
  end

  # Helper to test resource not found
  def test_not_found(action, params = {})
    params[:id] ||= 99_999
    send(action, params)
    expect(response).to have_http_status(:not_found)
  end

  # Helper to test validation errors
  def test_validation_errors(action, invalid_params, expected_errors)
    send(action, params: invalid_params)
    expect(response).to have_http_status(:unprocessable_entity)

    errors = json_response["error"] || json_response["errors"]
    expected_errors.each do |error|
      expect(errors).to include(error)
    end
  end

  # Helper to test that an action changes a value
  def expect_to_change_value(object, attribute, from:, to:)
    expect do
      yield
      object.reload
    end.to change { object.send(attribute) }.from(from).to(to)
  end

  # Helper to test that an action doesn't change a value
  def expect_not_to_change_value(object, attribute)
    expect do
      yield
      object.reload
    end.not_to(change { object.send(attribute) })
  end

  # Helper to create test data with specific dates
  def create_with_dates(factory, dates_hash)
    dates_hash.map do |date, count|
      create_list(factory, count, created_at: date, updated_at: date)
    end.flatten
  end

  # Helper to test search functionality
  def test_search(path, search_param, query, expected_results)
    get path, params: { search_param => query }
    expect_json_success

    results = json_response["data"]
    expect(results.count).to eq(expected_results.count)

    result_ids = results.pluck("id")
    expected_ids = expected_results.map(&:id)
    expect(result_ids).to match_array(expected_ids)
  end

  # Helper to test batch operations
  def test_batch_operation(path, method, ids, expected_changes)
    initial_states = {}
    ids.each do |id|
      resource = expected_changes[:model].find(id)
      initial_states[id] = resource.attributes.dup
    end

    send(method, path, params: { ids: ids })
    expect_json_success

    ids.each do |id|
      resource = expected_changes[:model].find(id)
      expected_changes[:attributes].each do |attr, value|
        expect(resource.send(attr)).to eq(value)
      end
    end
  end

  # Helper to test async operations
  def test_async_operation(path, method, params)
    send(method, path, params: params)
    expect(response).to have_http_status(:accepted)

    # Allow time for async processing
    sleep 0.1

    yield if block_given?
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
