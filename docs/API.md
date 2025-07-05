# StreamSource API Documentation

## Overview

The StreamSource API is a RESTful service that provides programmatic access to manage streamers, streams, and timestamps. It uses JWT authentication and returns JSON responses.

### Base URL
- Development: `http://localhost:3000/api/v1`
- Production: `https://your-domain.com/api/v1`

### Interactive Documentation
Visit `/api-docs` for interactive Swagger/OpenAPI documentation with a try-it-out feature.

## Authentication

### Overview
The API uses JWT (JSON Web Tokens) for authentication. Tokens expire after 24 hours.

### Getting a Token

#### Sign Up
```http
POST /api/v1/users/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123!",
  "password_confirmation": "Password123!"
}
```

**Response:**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "default"
  }
}
```

#### Login
```http
POST /api/v1/users/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123!"
}
```

**Response:**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "default"
  }
}
```

### Using the Token

Include the JWT token in the Authorization header for all authenticated requests:

```http
GET /api/v1/streams
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

### Password Requirements
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character

## Rate Limiting

The API implements rate limiting to prevent abuse:

- **Default limit**: 60 requests per minute per IP
- **Authenticated users**: Higher limits may apply
- **Response headers**:
  - `X-RateLimit-Limit`: Request limit
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Reset timestamp

When rate limited, you'll receive:
```json
{
  "error": "Rate limit exceeded. Try again later."
}
```

## Pagination

All list endpoints support pagination using the Pagy gem:

### Query Parameters
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 25, max: 100)

### Response Headers
- `X-Total-Count` - Total number of items
- `X-Page` - Current page
- `X-Per-Page` - Items per page
- `Link` - Navigation links (first, prev, next, last)

Example:
```http
GET /api/v1/streams?page=2&per_page=50
```

## Common Response Codes

- `200 OK` - Successful request
- `201 Created` - Resource created
- `204 No Content` - Successful request with no response body
- `400 Bad Request` - Invalid request parameters
- `401 Unauthorized` - Missing or invalid authentication
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation errors
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

## Error Responses

Errors follow a consistent format:

```json
{
  "error": "Error message",
  "details": {
    "field_name": ["validation error 1", "validation error 2"]
  }
}
```

## Endpoints

### Streams

#### List Streams
```http
GET /api/v1/streams
```

**Query Parameters:**
- `status` - Filter by status (checking, live, offline, error, archived)
- `user_id` - Filter by user
- `streamer_id` - Filter by streamer
- `platform` - Filter by platform
- `pinned` - Filter by pinned status (true/false)
- `archived` - Include archived streams (true/false)
- `search` - Search in URL and notes
- `sort` - Sort field (created_at, updated_at, checked_at)
- `direction` - Sort direction (asc, desc)

**Response:**
```json
{
  "streams": [
    {
      "id": 1,
      "url": "https://twitch.tv/example",
      "status": "live",
      "pinned": false,
      "archived": false,
      "checked_at": "2024-01-15T10:30:00Z",
      "started_at": "2024-01-15T10:00:00Z",
      "viewer_count": 1250,
      "user": {
        "id": 1,
        "email": "user@example.com"
      },
      "streamer": {
        "id": 1,
        "name": "Example Streamer"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 125
  }
}
```

#### Get Stream
```http
GET /api/v1/streams/:id
```

**Response:**
```json
{
  "id": 1,
  "url": "https://twitch.tv/example",
  "status": "live",
  "pinned": false,
  "archived": false,
  "checked_at": "2024-01-15T10:30:00Z",
  "started_at": "2024-01-15T10:00:00Z",
  "viewer_count": 1250,
  "notes": "Special event stream",
  "user": {
    "id": 1,
    "email": "user@example.com"
  },
  "streamer": {
    "id": 1,
    "name": "Example Streamer",
    "platform": "twitch"
  },
  "timestamps": [
    {
      "id": 1,
      "timestamp": "00:15:30",
      "description": "Technical difficulties"
    }
  ]
}
```

#### Create Stream
```http
POST /api/v1/streams
Content-Type: application/json

{
  "stream": {
    "url": "https://twitch.tv/newstream",
    "streamer_id": 1,
    "notes": "New gaming stream",
    "location": {
      "city": "Austin",
      "state_province": "TX",
      "country": "USA"
    }
  }
}
```

**Alternative with existing location:**
```json
{
  "stream": {
    "url": "https://twitch.tv/newstream",
    "streamer_id": 1,
    "location_id": 5
  }
}
```

**Response:** 201 Created
```json
{
  "id": 2,
  "url": "https://twitch.tv/newstream",
  "status": "checking",
  "streamer_id": 1,
  "notes": "New gaming stream",
  "location_id": 5,
  "location": {
    "id": 5,
    "city": "Austin",
    "state_province": "TX",
    "country": "USA",
    "display_name": "Austin, TX"
  }
}
```

#### Update Stream
```http
PATCH /api/v1/streams/:id
Content-Type: application/json

{
  "stream": {
    "notes": "Updated notes",
    "pinned": true
  }
}
```

**Response:** 200 OK

#### Delete Stream
```http
DELETE /api/v1/streams/:id
```

**Response:** 204 No Content

#### Pin Stream
```http
PUT /api/v1/streams/:id/pin
```

**Response:** 200 OK

#### Unpin Stream
```http
DELETE /api/v1/streams/:id/pin
```

**Response:** 200 OK

#### Archive Stream
```http
POST /api/v1/streams/:id/archive
```

**Response:** 200 OK

#### Unarchive Stream
```http
POST /api/v1/streams/:id/unarchive
```

**Response:** 200 OK

### Streamers

#### List Streamers
```http
GET /api/v1/streamers
```

**Query Parameters:**
- `search` - Search by name
- `platform` - Filter by platform

**Response:**
```json
{
  "streamers": [
    {
      "id": 1,
      "name": "Example Streamer",
      "created_at": "2024-01-01T00:00:00Z",
      "accounts": [
        {
          "id": 1,
          "platform": "twitch",
          "username": "examplestreamer",
          "profile_url": "https://twitch.tv/examplestreamer"
        }
      ],
      "streams_count": 15,
      "active_streams_count": 2
    }
  ]
}
```

#### Get Streamer
```http
GET /api/v1/streamers/:id
```

#### Create Streamer
```http
POST /api/v1/streamers
Content-Type: application/json

{
  "streamer": {
    "name": "New Streamer",
    "accounts_attributes": [
      {
        "platform": "twitch",
        "username": "newstreamer"
      }
    ]
  }
}
```

**Response:** 201 Created

#### Update Streamer
```http
PATCH /api/v1/streamers/:id
Content-Type: application/json

{
  "streamer": {
    "name": "Updated Name",
    "accounts_attributes": [
      {
        "id": 1,
        "username": "updatedusername"
      }
    ]
  }
}
```

#### Delete Streamer
```http
DELETE /api/v1/streamers/:id
```

**Response:** 204 No Content

### Timestamps

#### List Timestamps
```http
GET /api/v1/timestamps
```

**Query Parameters:**
- `stream_id` - Filter by stream
- `priority` - Filter by priority (low, medium, high)
- `status` - Filter by status

**Response:**
```json
{
  "timestamps": [
    {
      "id": 1,
      "timestamp": "00:15:30",
      "description": "Technical issue",
      "priority": "high",
      "status": "pending",
      "created_at": "2024-01-15T10:30:00Z",
      "user": {
        "id": 1,
        "email": "user@example.com"
      },
      "streams": [
        {
          "id": 1,
          "url": "https://twitch.tv/example"
        }
      ]
    }
  ]
}
```

#### Get Timestamp
```http
GET /api/v1/timestamps/:id
```

#### Create Timestamp
```http
POST /api/v1/timestamps
Content-Type: application/json

{
  "timestamp": {
    "timestamp": "00:45:20",
    "description": "Highlight moment",
    "priority": "medium",
    "stream_ids": [1, 2]
  }
}
```

**Response:** 201 Created

#### Update Timestamp
```http
PATCH /api/v1/timestamps/:id
Content-Type: application/json

{
  "timestamp": {
    "description": "Updated description",
    "priority": "low",
    "status": "resolved"
  }
}
```

#### Delete Timestamp
```http
DELETE /api/v1/timestamps/:id
```

**Response:** 204 No Content

### Locations

Locations represent cities/regions where streams originate. They support automatic creation when adding streams and provide client-side validation capabilities.

#### List Locations
```http
GET /api/v1/locations
```

**Query Parameters:**
- `search` - Search in city, state_province, region, or country
- `country` - Filter by country
- `state` - Filter by state/province
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 25)

**Response:**
```json
{
  "locations": [
    {
      "id": 1,
      "city": "Austin",
      "state_province": "TX",
      "region": "Southwest",
      "country": "USA",
      "display_name": "Austin, TX",
      "full_display_name": "Austin, TX, USA",
      "normalized_name": "austin, tx, usa",
      "latitude": "30.2672",
      "longitude": "-97.7431",
      "coordinates": [30.2672, -97.7431],
      "streams_count": 42,
      "created_at": "2024-01-15T10:00:00Z",
      "updated_at": "2024-01-15T10:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 125
  }
}
```

#### Get All Locations (No Pagination)
```http
GET /api/v1/locations/all
```

Returns all locations for client-side validation. This endpoint is cached for 5 minutes.

**Response:**
```json
{
  "locations": [
    {
      "id": 1,
      "city": "Austin",
      "state_province": "TX",
      "country": "USA",
      "display_name": "Austin, TX",
      "normalized_name": "austin, tx, usa"
    },
    // ... all locations
  ]
}
```

#### Get Location
```http
GET /api/v1/locations/:id
```

**Response:**
```json
{
  "id": 1,
  "city": "Austin",
  "state_province": "TX",
  "region": "Southwest",
  "country": "USA",
  "display_name": "Austin, TX",
  "full_display_name": "Austin, TX, USA",
  "normalized_name": "austin, tx, usa",
  "latitude": "30.2672",
  "longitude": "-97.7431",
  "coordinates": [30.2672, -97.7431],
  "streams_count": 42,
  "created_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-15T10:00:00Z"
}
```

#### Create Location
```http
POST /api/v1/locations
Content-Type: application/json

{
  "location": {
    "city": "Seattle",
    "state_province": "WA",
    "country": "USA",
    "latitude": 47.6062,
    "longitude": -122.3321
  }
}
```

**Response:** 201 Created

#### Update Location
```http
PATCH /api/v1/locations/:id
Content-Type: application/json

{
  "location": {
    "region": "Pacific Northwest",
    "latitude": 47.6062,
    "longitude": -122.3321
  }
}
```

**Response:** 200 OK

#### Delete Location
```http
DELETE /api/v1/locations/:id
```

**Response:** 204 No Content

**Note:** Locations cannot be deleted if they are associated with any streams.

### Feature-Flagged Endpoints

These endpoints are only available when their respective feature flags are enabled:

#### Stream Analytics
```http
GET /api/v1/streams/:id/analytics
```

**Feature Flag:** `analytics`

**Response:**
```json
{
  "stream_id": 1,
  "total_duration": 7200,
  "average_viewers": 1250,
  "peak_viewers": 2500,
  "engagement_rate": 0.85
}
```

#### Export Streams
```http
GET /api/v1/streams/export
```

**Feature Flag:** `export`

**Query Parameters:**
- `format` - Export format (json, csv)
- All stream filter parameters

#### Bulk Import
```http
POST /api/v1/streams/bulk_import
Content-Type: application/json

{
  "streams": [
    {
      "url": "https://twitch.tv/stream1",
      "streamer_id": 1
    },
    {
      "url": "https://youtube.com/stream2",
      "streamer_id": 2
    }
  ]
}
```

**Feature Flag:** `bulk_import`

**Response:** 201 Created
```json
{
  "imported": 2,
  "failed": 0,
  "errors": []
}
```

## WebSocket Support

### ActionCable Connection

Connect to the WebSocket endpoint for real-time updates:

```javascript
// JavaScript example
import { createConsumer } from "@rails/actioncable"

const consumer = createConsumer("wss://your-domain.com/cable")

// Subscribe to streams channel
const subscription = consumer.subscriptions.create(
  { channel: "StreamsChannel" },
  {
    received(data) {
      console.log("Stream update:", data)
      // Handle real-time updates
    }
  }
)
```

### Events

The WebSocket connection broadcasts these events:

- `stream.updated` - Stream status or data changed
- `stream.created` - New stream added
- `stream.deleted` - Stream removed
- `stream.pinned` - Stream pinned/unpinned
- `stream.archived` - Stream archived/unarchived

## Health & Monitoring

### Health Check
```http
GET /health
```

**Response:** 200 OK
```json
{
  "status": "ok"
}
```

### Liveness Probe
```http
GET /health/live
```

### Readiness Probe
```http
GET /health/ready
```

### Metrics (Prometheus format)
```http
GET /metrics
```

## Best Practices

### 1. Handle Rate Limits
- Implement exponential backoff
- Cache responses when possible
- Use webhooks for real-time updates instead of polling

### 2. Efficient Pagination
- Use reasonable page sizes (25-50 items)
- Don't request all pages at once
- Use filters to reduce result sets

### 3. Error Handling
- Always check response status codes
- Parse error messages for user feedback
- Implement retry logic for transient errors

### 4. Security
- Store JWT tokens securely
- Refresh tokens before expiration
- Use HTTPS in production
- Don't log sensitive data

### 5. Performance
- Use field selection when available
- Batch operations when possible
- Implement client-side caching
- Use WebSockets for real-time data

## SDK Examples

### Ruby
```ruby
require 'net/http'
require 'json'

class StreamSourceClient
  BASE_URL = 'https://your-domain.com/api/v1'
  
  def initialize(token)
    @token = token
  end
  
  def get_streams(params = {})
    uri = URI("#{BASE_URL}/streams")
    uri.query = URI.encode_www_form(params)
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    
    JSON.parse(response.body)
  end
end
```

### Python
```python
import requests

class StreamSourceClient:
    def __init__(self, token, base_url='https://your-domain.com/api/v1'):
        self.token = token
        self.base_url = base_url
        self.headers = {'Authorization': f'Bearer {token}'}
    
    def get_streams(self, **params):
        response = requests.get(
            f'{self.base_url}/streams',
            headers=self.headers,
            params=params
        )
        response.raise_for_status()
        return response.json()
```

### JavaScript/Node.js
```javascript
class StreamSourceClient {
  constructor(token, baseURL = 'https://your-domain.com/api/v1') {
    this.token = token;
    this.baseURL = baseURL;
  }

  async getStreams(params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const response = await fetch(`${this.baseURL}/streams?${queryString}`, {
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
  }
}
```

## Changelog

### Version 1.0 (Current)
- JWT authentication
- Full CRUD for streams, streamers, timestamps
- Real-time WebSocket updates
- Advanced filtering and search
- Rate limiting
- Feature flags support

## Support

- **API Documentation**: `/api-docs`
- **GitHub Issues**: Report bugs and feature requests
- **Email Support**: api-support@your-domain.com