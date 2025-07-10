# Known Cities Integration Guide

## Overview

StreamSource now supports a "known cities" feature that allows administrators to maintain a list of verified/known cities. When enabled via feature flag, the system will validate location inputs against this list.

## Feature Flag

The feature is controlled by the `LOCATION_VALIDATION` feature flag. When disabled, the system behaves as before - any city name can be entered.

```ruby
# Enable location validation
Flipper.enable(ApplicationConstants::Features::LOCATION_VALIDATION)

# Enable for specific groups
Flipper.enable_group(ApplicationConstants::Features::LOCATION_VALIDATION, :admins)
```

## Database Schema

Added to the `locations` table:
- `is_known_city` (boolean, default: false) - Marks a location as verified/known

## API Endpoints

### Get All Locations
```
GET /api/v1/locations/all
```
Returns all locations including `is_known_city` flag.

### Get Known Cities Only
```
GET /api/v1/locations/known_cities
```
Returns only verified cities (where `is_known_city = true`).

Both endpoints are cached for performance:
- `/all` - 5 minutes
- `/known_cities` - 15 minutes

## Integration with Other Services

### livestream-link-monitor

When posting streams to StreamSource API:

```javascript
// Before creating stream, optionally validate location
const response = await fetch(`${STREAMSOURCE_API_URL}/locations/known_cities`, {
  headers: { 'Authorization': `Bearer ${token}` }
});
const knownCities = await response.json();

// Check if city is known
const isKnown = knownCities.locations.some(loc => 
  loc.normalized_name === normalizeCity(city, state)
);

if (!isKnown) {
  console.warn(`City "${city}, ${state}" is not in known cities list`);
  // Decide whether to:
  // 1. Skip the stream
  // 2. Post anyway (will fail if validation is enabled)
  // 3. Use a default/closest known city
}

// When creating stream
const streamData = {
  // ... other fields
  location: {
    city: city,
    state_province: state
  }
};

// If validation is enabled and city is not known, this will return:
// 422 Unprocessable Entity
// {
//   "error": "Location validation failed: City is not a recognized city. Please contact an admin to add it."
// }
```

### Streamwall

The Streamwall application can use the known cities for:

1. **Autocomplete** - Fetch known cities for location input
2. **Validation** - Show warnings for unknown cities
3. **Filtering** - Filter streams by known cities only

```javascript
// Fetch known cities for autocomplete
async function getKnownCities() {
  const response = await fetch(`${API_URL}/locations/known_cities`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  return response.json();
}

// Use in autocomplete component
const cities = await getKnownCities();
// cities.locations array contains normalized city data
```

### livesheet-updater

No direct integration needed, but the service should be aware that:
- New streams might be rejected if using unknown cities

## Admin Interface

Administrators can manage known cities at `/admin/locations`:

1. View all locations with visual indicator for known cities (✓)
2. Add new locations and mark them as known
3. Edit existing locations to mark/unmark as known
4. Search and filter locations

## Migration Strategy

1. **Phase 1**: Deploy with feature flag disabled
   - All existing behavior continues
   - Admins can start marking cities as known

2. **Phase 2**: Enable for testing
   - Enable flag for specific users/groups
   - Monitor for validation errors

3. **Phase 3**: Full rollout
   - Enable globally
   - All location inputs validated

## Error Handling

When location validation fails:

**API Response**:
```json
{
  "error": "Location validation failed: City is not a recognized city. Please contact an admin to add it."
}
```

**Admin Interface**: Shows inline error on city field

## Best Practices

1. **Pre-populate known cities** before enabling validation
2. **Monitor logs** for validation failures
3. **Provide feedback mechanism** for users to request new cities
4. **Cache known cities** client-side to reduce API calls
5. **Use normalized names** for consistent matching

## Example: Adding Known Cities via Rails Console

```ruby
# Add a single known city
Location.create!(
  city: "Austin",
  state_province: "TX",
  country: "USA",
  is_known_city: true
)

# Mark existing locations as known
Location.where(city: ["New York", "Los Angeles", "Chicago"])
        .update_all(is_known_city: true)

# Import from CSV
CSV.foreach("known_cities.csv", headers: true) do |row|
  Location.find_or_create_by(
    normalized_name: Location.normalize_location_name(
      row["city"], 
      row["state"], 
      row["country"]
    )
  ) do |loc|
    loc.city = row["city"]
    loc.state_province = row["state"]
    loc.country = row["country"]
    loc.is_known_city = true
  end
end
```