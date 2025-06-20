# Feature Flags Documentation

This document describes the feature flag system implemented using Flipper in the StreamSource API.

## Overview

Feature flags allow you to:
- Enable/disable features without deploying code
- Gradually roll out features to specific users or groups
- A/B test new functionality
- Quickly disable problematic features

## Accessing Flipper UI

The Flipper UI is available at `/admin/feature_flags` for admin users only.

To access:
1. Login as an admin user at `/admin/login`
2. Navigate to `http://localhost:3000/admin/feature_flags`
3. Use the UI to manage feature flags

Note: The Flipper UI is protected by basic auth middleware (AdminFlipperAuth) that requires admin role.

## Available Feature Flags

Note: The application has grown beyond the initial feature set. New features like Streamers, Annotations, and Notes are not feature-flagged but are core functionality. The following flags remain available:

### Stream Features

#### `stream_analytics`
- **Description**: Enables analytics data for streams
- **Default**: Enabled for all
- **Effects**: 
  - Adds `/analytics` endpoint to streams
  - Includes `analytics_url` in stream JSON responses

#### `stream_bulk_import`
- **Description**: Allows bulk importing of streams
- **Default**: Enabled for editors group
- **Effects**: 
  - Enables `POST /api/v1/streams/bulk_import` endpoint

#### `stream_export`
- **Description**: Allows exporting stream data
- **Default**: Enabled for all
- **Effects**: 
  - Enables `GET /api/v1/streams/export` endpoint

#### `stream_webhooks`
- **Description**: Webhook notifications for stream events
- **Default**: Disabled
- **Effects**: 
  - Would trigger webhooks on stream create/update/delete

#### `stream_tags`
- **Description**: Tagging system for streams
- **Default**: Enabled for admins
- **Effects**: 
  - Includes `tags` field in stream responses
  - Would enable tag management endpoints

#### `stream_scheduling`
- **Description**: Schedule streams to go live/offline
- **Default**: Disabled
- **Effects**: 
  - Would add scheduling fields and logic

### User Features

#### `user_profile_customization`
- **Description**: Extended user profile options
- **Default**: Disabled
- **Effects**: 
  - Would add profile customization endpoints

#### `user_two_factor_auth`
- **Description**: Two-factor authentication
- **Default**: Disabled
- **Effects**: 
  - Would add 2FA setup and verification

#### `user_api_keys`
- **Description**: Personal API key management
- **Default**: Disabled
- **Effects**: 
  - Would allow users to generate API keys

#### `user_activity_log`
- **Description**: User activity tracking
- **Default**: Disabled
- **Effects**: 
  - Would log and display user activities

### API Features

#### `api_graphql`
- **Description**: GraphQL API endpoint
- **Default**: Disabled
- **Effects**: 
  - Would mount GraphQL endpoint

#### `api_websockets`
- **Description**: WebSocket support for real-time updates
- **Default**: Enabled (ActionCable is active)
- **Effects**: 
  - Enables WebSocket connections at `/cable`
  - Supports StreamChannel, AnnotationChannel, AdminChannel

#### `api_v2`
- **Description**: Version 2 of the API
- **Default**: Disabled
- **Effects**: 
  - Would enable v2 endpoints

### System Features

#### `advanced_search`
- **Description**: Advanced search functionality
- **Default**: Enabled for all
- **Effects**: 
  - Would add advanced search endpoints

#### `real_time_notifications`
- **Description**: Real-time notification system
- **Default**: Disabled
- **Effects**: 
  - Would enable push notifications

#### `maintenance_mode`
- **Description**: Put API in maintenance mode
- **Default**: Disabled
- **Effects**: 
  - Returns 503 for all non-health endpoints
  - Shows maintenance message

### Experimental Features

#### `ai_stream_recommendations`
- **Description**: AI-powered stream recommendations
- **Default**: 10% rollout
- **Effects**: 
  - Would add recommendation endpoints

#### `collaborative_playlists`
- **Description**: Shared playlist functionality
- **Default**: Disabled
- **Effects**: 
  - Would enable playlist sharing features

## Usage in Code

### Checking if a feature is enabled

```ruby
# Check globally
if Flipper.enabled?(:stream_analytics)
  # Feature is enabled
end

# Check for specific user
if Flipper.enabled?(:stream_analytics, current_user)
  # Feature is enabled for this user
end

# Check for group
if Flipper.enabled?(:stream_bulk_import, :editors)
  # Feature is enabled for editors
end
```

### In Controllers

```ruby
def analytics
  unless Flipper.enabled?(:stream_analytics, current_user)
    render_error('This feature is not currently available', :forbidden)
    return
  end
  
  # Feature logic here
end
```

### In Serializers

```ruby
class StreamSerializer < ActiveModel::Serializer
  attribute :analytics_url, if: :show_analytics?
  
  def show_analytics?
    Flipper.enabled?(:stream_analytics, current_user)
  end
end
```

## Managing Feature Flags

### Via Rails Console

```ruby
# Enable for everyone
Flipper.enable(:stream_analytics)

# Enable for specific user
user = User.find(1)
Flipper.enable_actor(:stream_analytics, user)

# Enable for group
Flipper.enable_group(:stream_bulk_import, :editors)

# Enable for percentage
Flipper.enable_percentage_of_actors(:ai_recommendations, 25)

# Disable completely
Flipper.disable(:maintenance_mode)
```

### Via Flipper UI

1. Navigate to `/admin/feature_flags`
2. Find the feature in the list
3. Use the toggles to enable/disable for:
   - All users
   - Specific groups
   - Percentage of users
   - Individual actors

### Via API (if implemented)

```bash
# Enable feature
curl -X POST http://localhost:3000/admin/features/stream_analytics/enable \
  -H "Authorization: Bearer <admin-token>"

# Disable feature
curl -X POST http://localhost:3000/admin/features/stream_analytics/disable \
  -H "Authorization: Bearer <admin-token>"
```

## Groups

The following groups are defined:

- **admins**: Users with `role: 'admin'`
- **editors**: Users with `role: 'editor'`
- **beta_users**: Users marked as beta testers
- **premium_users**: Users with premium status

## Best Practices

1. **Start with small rollouts**: Use percentage or group rollouts before enabling globally
2. **Monitor after enabling**: Watch logs and metrics after enabling features
3. **Document features**: Keep this document updated with new flags
4. **Clean up old flags**: Remove flags for features that are permanently enabled
5. **Use descriptive names**: Feature names should clearly indicate what they control

## Testing with Feature Flags

```ruby
# In RSpec tests
describe 'with feature enabled' do
  before { enable_feature(:stream_analytics) }
  after { disable_feature(:stream_analytics) }
  
  it 'shows analytics' do
    # Test with feature enabled
  end
end

# Test with specific actor
with_feature(:stream_analytics, user) do
  # Test code
end
```

## Monitoring

Feature flag usage can be monitored through:

1. **Logs**: Feature checks are logged in development
2. **Metrics**: Track feature adoption rates
3. **Flipper UI**: See current state of all features

## Emergency Procedures

### Disable All Features

```ruby
# In Rails console
Flipper.features.each do |feature|
  Flipper.disable(feature.key)
end
```

### Enable Maintenance Mode

```ruby
# Via console
Flipper.enable(:maintenance_mode)

# Via direct DB (if console unavailable)
# UPDATE flipper_features SET enabled = true WHERE key = 'maintenance_mode';
```

### Quick Rollback

```ruby
# Disable problematic feature
Flipper.disable(:problematic_feature)

# Or reduce rollout
Flipper.enable_percentage_of_actors(:problematic_feature, 5)
```