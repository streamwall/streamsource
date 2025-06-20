# StreamSource API Documentation

## Base URL
```
http://localhost:3000/api/v1
```

## Authentication

The API uses JWT (JSON Web Token) authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

Tokens expire after 24 hours.

## Rate Limiting

All endpoints are rate limited:
- General: 100 requests per minute per IP
- Login: 5 attempts per 20 minutes per IP/email
- Signup: 3 attempts per hour per IP

Rate limit headers are included in responses:
- `X-RateLimit-Limit`: Maximum requests allowed
- `X-RateLimit-Remaining`: Requests remaining
- `X-RateLimit-Reset`: Time when limit resets (Unix timestamp)

## Common Response Codes

- `200 OK`: Success
- `201 Created`: Resource created successfully
- `204 No Content`: Success with no response body
- `400 Bad Request`: Invalid request parameters
- `401 Unauthorized`: Missing or invalid authentication
- `403 Forbidden`: Authenticated but not authorized
- `404 Not Found`: Resource not found
- `422 Unprocessable Entity`: Validation errors
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

## Endpoints

### Authentication

#### Sign Up
Create a new user account.

**Endpoint:** `POST /users/signup`

**Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123",
  "role": "default"
}
```

**Parameters:**
- `email` (required): Valid email address
- `password` (required): Minimum 8 characters, must include uppercase, lowercase, and number
- `role` (optional): User role - `default`, `editor`, or `admin` (defaults to `default`)

**Response:**
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "default",
    "created_at": "2024-01-01T12:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z"
  },
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

#### Login
Authenticate and receive a JWT token.

**Endpoint:** `POST /users/login`

**Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123"
}
```

**Response:**
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "editor",
    "created_at": "2024-01-01T12:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z"
  },
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

### Streams

#### List Streams
Get a paginated list of streams.

**Endpoint:** `GET /streams`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Items per page (default: 25, max: 100)
- `status` (optional): Filter by status (`active`, `inactive`, `live`, `ended`, etc.)
- `notStatus` (optional): Exclude streams with this status
- `user_id` (optional): Filter by user ID
- `streamer_id` (optional): Filter by streamer ID
- `platform` (optional): Filter by platform
- `is_pinned` (optional): Filter by pin state (`true` or `false`)
- `is_archived` (optional): Filter by archive state (`true` or `false`)

**Response:**
```json
{
  "streams": [
    {
      "id": 1,
      "title": "Example Stream",
      "source": "YouTube Channel",
      "link": "https://example.com/stream1",
      "city": "New York",
      "state": "NY",
      "platform": "youtube",
      "status": "live",
      "orientation": "landscape",
      "kind": "livestream",
      "is_pinned": false,
      "is_archived": false,
      "started_at": "2024-01-01T11:00:00Z",
      "ended_at": null,
      "created_at": "2024-01-01T12:00:00Z",
      "updated_at": "2024-01-01T12:00:00Z",
      "user": {
        "id": 1,
        "email": "user@example.com",
        "role": "editor"
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
    "total_count": 123,
    "per_page": 25
  }
}
```

#### Get Stream
Get a specific stream by ID.

**Endpoint:** `GET /streams/:id`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Response:**
```json
{
  "id": 1,
  "title": "Example Stream",
  "source": "YouTube Channel",
  "link": "https://example.com/stream1",
  "city": "New York",
  "state": "NY",
  "platform": "youtube",
  "status": "live",
  "orientation": "landscape",
  "kind": "livestream",
  "is_pinned": false,
  "is_archived": false,
  "started_at": "2024-01-01T11:00:00Z",
  "ended_at": null,
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "editor"
  },
  "streamer": {
    "id": 1,
    "name": "Example Streamer",
    "description": "A popular content creator"
  },
  "notes_count": 3
}
```

#### Create Stream
Create a new stream (requires `editor` or `admin` role).

**Endpoint:** `POST /streams`

**Headers:**
- `Authorization: Bearer <token>` (required)
- `Content-Type: application/json`

**Body:**
```json
{
  "title": "My New Stream",
  "source": "Example Source",
  "link": "https://example.com/new-stream",
  "city": "New York",
  "state": "NY",
  "platform": "youtube",
  "status": "live",
  "orientation": "landscape",
  "kind": "livestream",
  "streamer_id": 1,
  "stream_url_id": 1
}
```

**Parameters:**
- `title` (required): Stream title (1-255 characters)
- `source` (required): Stream source
- `link` (required): Valid HTTP or HTTPS URL
- `city` (optional): City location
- `state` (optional): State/region location
- `platform` (optional): Streaming platform
- `status` (optional): Stream status - `active`, `inactive`, `live`, `ended`, etc.
- `orientation` (optional): Video orientation - `landscape`, `portrait`, `square`
- `kind` (optional): Stream type
- `streamer_id` (optional): Associated streamer ID
- `stream_url_id` (optional): Associated stream URL ID

**Response:**
Same as Get Stream response.
```

#### Update Stream
Update an existing stream (owner or `admin` only).

**Endpoint:** `PATCH /streams/:id`

**Headers:**
- `Authorization: Bearer <token>` (required)
- `Content-Type: application/json`

**Body:**
```json
{
  "title": "Updated Stream Title",
  "link": "https://example.com/updated-stream",
  "status": "ended",
  "ended_at": "2024-01-01T13:00:00Z"
}
```

**Parameters:**
- `title` (optional): New stream title
- `source` (optional): New stream source
- `link` (optional): New stream URL
- `status` (optional): New status
- `city` (optional): New city
- `state` (optional): New state
- `platform` (optional): New platform
- `orientation` (optional): New orientation
- `kind` (optional): New stream type
- `started_at` (optional): When stream started
- `ended_at` (optional): When stream ended

**Response:**
Same as Get Stream response with updated values.

#### Delete Stream
Delete a stream (owner or `admin` only).

**Endpoint:** `DELETE /streams/:id`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Response:**
`204 No Content` on success

#### Pin Stream
Pin a stream to highlight it (owner or `admin` only).

**Endpoint:** `PUT /streams/:id/pin`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Response:**
Same as Get Stream response with `is_pinned: true`

#### Unpin Stream
Remove pin from a stream (owner or `admin` only).

**Endpoint:** `DELETE /streams/:id/pin`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Response:**
Same as Get Stream response with `is_pinned: false`

#### Archive Stream
Archive a stream (owner or `admin` only).

**Endpoint:** `POST /streams/:id/archive`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Response:**
Same as Get Stream response with `is_archived: true`

#### Unarchive Stream
Unarchive a stream (owner or `admin` only).

**Endpoint:** `POST /streams/:id/unarchive`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Response:**
Same as Get Stream response with `is_archived: false`

#### Stream Analytics (Feature Flagged)
Get analytics data for a stream.

**Endpoint:** `GET /streams/:id/analytics`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Note:** This endpoint requires the `stream_analytics` feature flag to be enabled for the user.

**Response:**
```json
{
  "stream_id": 1,
  "views_count": 5432,
  "unique_viewers": 876,
  "average_watch_time": 1823,
  "peak_concurrent_viewers": 234,
  "last_updated": "2024-01-01T12:00:00Z"
}
```

#### Bulk Import Streams (Feature Flagged)
Import multiple streams at once.

**Endpoint:** `POST /streams/bulk_import`

**Headers:**
- `Authorization: Bearer <token>` (required)
- `Content-Type: application/json`

**Note:** This endpoint requires the `stream_bulk_import` feature flag to be enabled (default: editors only).

**Body:**
```json
{
  "streams": [
    {
      "title": "Stream 1",
      "source": "YouTube",
      "link": "https://example.com/stream1",
      "status": "live",
      "platform": "youtube"
    },
    {
      "title": "Stream 2",
      "source": "Twitch",
      "link": "https://example.com/stream2",
      "status": "live",
      "platform": "twitch"
    }
  ]
}
```

**Response:**
```json
{
  "imported": 2,
  "total": 2,
  "errors": []
}
```

#### Export Streams (Feature Flagged)
Export stream data in JSON format.

**Endpoint:** `GET /streams/export`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Query Parameters:**
- Same filtering options as List Streams

**Note:** This endpoint requires the `stream_export` feature flag to be enabled.

**Response:**
```json
{
  "exported_at": "2024-01-01T12:00:00Z",
  "count": 25,
  "streams": [
    {
      "title": "Stream Title",
      "source": "YouTube Channel",
      "link": "https://example.com/stream",
      "platform": "youtube",
      "status": "live",
      "is_pinned": false,
      "is_archived": false,
      "created_at": "2024-01-01T10:00:00Z",
      "owner_email": "user@example.com",
      "streamer_name": "Example Streamer"
    }
  ]
}
```

### Streamers

#### List Streamers
Get a paginated list of streamers.

**Endpoint:** `GET /streamers`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Items per page (default: 25, max: 100)

**Response:**
```json
{
  "streamers": [
    {
      "id": 1,
      "name": "Example Streamer",
      "description": "A popular content creator",
      "created_at": "2024-01-01T12:00:00Z",
      "updated_at": "2024-01-01T12:00:00Z",
      "streams_count": 15,
      "accounts_count": 3
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 123,
    "per_page": 25
  }
}
```

#### Get Streamer
Get a specific streamer by ID.

**Endpoint:** `GET /streamers/:id`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Response:**
```json
{
  "id": 1,
  "name": "Example Streamer",
  "description": "A popular content creator",
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z",
  "streams": [
    {
      "id": 1,
      "title": "Stream Title",
      "platform": "youtube",
      "status": "live"
    }
  ],
  "accounts": [
    {
      "id": 1,
      "platform": "youtube",
      "username": "examplestreamer",
      "url": "https://youtube.com/@examplestreamer"
    }
  ]
}
```

#### Create Streamer
Create a new streamer (requires `editor` or `admin` role).

**Endpoint:** `POST /streamers`

**Headers:**
- `Authorization: Bearer <token>` (required)
- `Content-Type: application/json`

**Body:**
```json
{
  "name": "New Streamer",
  "description": "Description of the streamer"
}
```

**Response:**
Same as Get Streamer response.

#### Update Streamer
Update an existing streamer (requires `editor` or `admin` role).

**Endpoint:** `PATCH /streamers/:id`

**Headers:**
- `Authorization: Bearer <token>` (required)
- `Content-Type: application/json`

**Body:**
```json
{
  "name": "Updated Name",
  "description": "Updated description"
}
```

**Response:**
Same as Get Streamer response with updated values.

#### Delete Streamer
Delete a streamer (requires `admin` role).

**Endpoint:** `DELETE /streamers/:id`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Response:**
`204 No Content` on success

### Annotations

#### List Annotations
Get a paginated list of annotations.

**Endpoint:** `GET /annotations`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Items per page (default: 25, max: 100)
- `priority` (optional): Filter by priority (`low`, `medium`, `high`, `critical`)
- `status` (optional): Filter by status (`pending`, `in_progress`, `resolved`, `closed`)

**Response:**
```json
{
  "annotations": [
    {
      "id": 1,
      "title": "Important Event",
      "description": "Description of the incident",
      "priority": "high",
      "status": "in_progress",
      "occurred_at": "2024-01-01T12:00:00Z",
      "created_at": "2024-01-01T12:05:00Z",
      "updated_at": "2024-01-01T12:10:00Z",
      "user": {
        "id": 1,
        "email": "user@example.com"
      },
      "streams_count": 3
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 3,
    "total_count": 67,
    "per_page": 25
  }
}
```

#### Get Annotation
Get a specific annotation by ID.

**Endpoint:** `GET /annotations/:id`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Response:**
```json
{
  "id": 1,
  "title": "Important Event",
  "description": "Detailed description of the incident",
  "priority": "high",
  "status": "in_progress",
  "occurred_at": "2024-01-01T12:00:00Z",
  "created_at": "2024-01-01T12:05:00Z",
  "updated_at": "2024-01-01T12:10:00Z",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "editor"
  },
  "streams": [
    {
      "id": 1,
      "title": "Stream 1",
      "platform": "youtube"
    },
    {
      "id": 2,
      "title": "Stream 2",
      "platform": "twitch"
    }
  ]
}
```

#### Create Annotation
Create a new annotation (requires `editor` or `admin` role).

**Endpoint:** `POST /annotations`

**Headers:**
- `Authorization: Bearer <token>` (required)
- `Content-Type: application/json`

**Body:**
```json
{
  "title": "New Incident",
  "description": "Description of what happened",
  "priority": "medium",
  "status": "pending",
  "occurred_at": "2024-01-01T12:00:00Z",
  "stream_ids": [1, 2, 3]
}
```

**Parameters:**
- `title` (required): Annotation title
- `description` (optional): Detailed description
- `priority` (required): Priority level - `low`, `medium`, `high`, `critical`
- `status` (optional): Status - `pending`, `in_progress`, `resolved`, `closed` (defaults to `pending`)
- `occurred_at` (required): When the incident occurred
- `stream_ids` (optional): Array of stream IDs to associate

**Response:**
Same as Get Annotation response.

#### Update Annotation
Update an existing annotation (owner or `admin` only).

**Endpoint:** `PATCH /annotations/:id`

**Headers:**
- `Authorization: Bearer <token>` (required)
- `Content-Type: application/json`

**Body:**
```json
{
  "title": "Updated Title",
  "status": "resolved",
  "stream_ids": [1, 2, 4]
}
```

**Response:**
Same as Get Annotation response with updated values.

#### Delete Annotation
Delete an annotation (owner or `admin` only).

**Endpoint:** `DELETE /annotations/:id`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Response:**
`204 No Content` on success

### Notes

#### Create Note
Create a note for a stream or streamer (requires authentication).

**Endpoint:** `POST /notes`

**Headers:**
- `Authorization: Bearer <token>` (required)
- `Content-Type: application/json`

**Body:**
```json
{
  "content": "This is a note about the stream",
  "notable_type": "Stream",
  "notable_id": 1
}
```

**Parameters:**
- `content` (required): Note content
- `notable_type` (required): Type of resource - `Stream` or `Streamer`
- `notable_id` (required): ID of the resource

**Response:**
```json
{
  "id": 1,
  "content": "This is a note about the stream",
  "notable_type": "Stream",
  "notable_id": 1,
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z",
  "user": {
    "id": 1,
    "email": "user@example.com"
  }
}
```

### Stream URLs

#### List Stream URLs
Get a list of stream URLs.

**Endpoint:** `GET /stream_urls`

**Headers:**
- `Authorization: Bearer <token>` (required)

**Response:**
```json
{
  "stream_urls": [
    {
      "id": 1,
      "url": "https://youtube.com/watch?v=abc123",
      "platform": "youtube",
      "is_active": true,
      "created_at": "2024-01-01T12:00:00Z",
      "updated_at": "2024-01-01T12:00:00Z",
      "streams_count": 5
    }
  ]
}
```

### WebSocket Connections

#### ActionCable Connection
Connect to the WebSocket endpoint for real-time updates.

**Endpoint:** `ws://localhost:3000/cable`

**Authentication:**
Include the JWT token as a query parameter:
```
ws://localhost:3000/cable?token=<your-jwt-token>
```

**Channels Available:**
- `StreamChannel`: Real-time stream updates
- `AnnotationChannel`: Real-time annotation updates

**Example (JavaScript):**
```javascript
import { createConsumer } from '@rails/actioncable';

const consumer = createConsumer(`ws://localhost:3000/cable?token=${authToken}`);

const streamChannel = consumer.subscriptions.create('StreamChannel', {
  received(data) {
    console.log('Stream update:', data);
  }
});
```

### Health Checks

#### Health Status
Basic health check endpoint.

**Endpoint:** `GET /health`

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z",
  "version": "1.0.0"
}
```

#### Liveness Check
Kubernetes liveness probe endpoint.

**Endpoint:** `GET /health/live`

**Response:**
```json
{
  "status": "ok"
}
```

#### Readiness Check
Kubernetes readiness probe endpoint (includes database check).

**Endpoint:** `GET /health/ready`

**Response (Success):**
```json
{
  "status": "ready",
  "database": "connected"
}
```

**Response (Failure):**
```json
{
  "status": "not ready",
  "error": "connection error message"
}
```

## Error Responses

All error responses follow a consistent format:

```json
{
  "error": "Error message describing what went wrong"
}
```

### Validation Errors

For validation errors, the message includes all validation failures:

```json
{
  "error": "Name can't be blank, Url must be a valid HTTP or HTTPS URL"
}
```

### Rate Limit Errors

When rate limited:

```json
{
  "error": "Too many requests. Please try again later."
}
```

## Roles and Permissions

### Default User
- View all streams
- Cannot create, update, or delete streams

### Editor
- All default user permissions
- Create new streams
- Update/delete own streams
- Pin/unpin own streams

### Admin
- All editor permissions
- Update/delete any stream
- Pin/unpin any stream

## Example Workflows

### Streamer Management Workflow

1. Create a streamer:
```bash
curl -X POST http://localhost:3000/api/v1/streamers \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"name": "Popular Streamer", "description": "Gaming content creator"}'
```

2. Add a stream for the streamer:
```bash
curl -X POST http://localhost:3000/api/v1/streams \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Live Gaming Session",
    "source": "YouTube",
    "link": "https://youtube.com/watch?v=xyz",
    "platform": "youtube",
    "status": "live",
    "streamer_id": 1
  }'
```

3. Create an annotation for an incident:
```bash
curl -X POST http://localhost:3000/api/v1/annotations \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Stream Interruption",
    "description": "Technical difficulties during stream",
    "priority": "high",
    "occurred_at": "2024-01-01T14:30:00Z",
    "stream_ids": [1]
  }'
```

### Complete Authentication Flow

1. Sign up:
```bash
curl -X POST http://localhost:3000/api/v1/users/signup \
  -H "Content-Type: application/json" \
  -d '{"email": "newuser@example.com", "password": "SecurePass123", "role": "editor"}'
```

2. Save the token from the response

3. Create a stream:
```bash
curl -X POST http://localhost:3000/api/v1/streams \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"title": "My Stream", "source": "YouTube", "link": "https://example.com/stream"}'
```

### Stream Management Workflow

1. List all active streams:
```bash
curl -X GET "http://localhost:3000/api/v1/streams?status=active" \
  -H "Authorization: Bearer <token>"
```

2. Pin an important stream:
```bash
curl -X PUT http://localhost:3000/api/v1/streams/1/pin \
  -H "Authorization: Bearer <token>"
```

3. Update stream details:
```bash
curl -X PATCH http://localhost:3000/api/v1/streams/1 \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"title": "Updated Title", "status": "ended", "ended_at": "2024-01-01T15:00:00Z"}'
```

## SDK Examples

### JavaScript/Node.js

```javascript
const API_BASE = 'http://localhost:3000/api/v1';
let authToken = '';

// Login
async function login(email, password) {
  const response = await fetch(`${API_BASE}/users/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  
  const data = await response.json();
  authToken = data.token;
  return data;
}

// Get streams
async function getStreams(params = {}) {
  const queryString = new URLSearchParams(params).toString();
  const response = await fetch(`${API_BASE}/streams?${queryString}`, {
    headers: { 'Authorization': `Bearer ${authToken}` }
  });
  
  return response.json();
}

// Create stream
async function createStream(title, source, link, platform = 'youtube') {
  const response = await fetch(`${API_BASE}/streams`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ title, source, link, platform })
  });
  
  return response.json();
}
```

### Ruby

```ruby
require 'net/http'
require 'json'

class StreamSourceClient
  API_BASE = 'http://localhost:3000/api/v1'
  
  def initialize
    @token = nil
  end
  
  def login(email, password)
    response = post('/users/login', { email: email, password: password })
    @token = response['token']
    response
  end
  
  def get_streams(params = {})
    get('/streams', params)
  end
  
  def create_stream(title, source, link, platform = 'youtube')
    post('/streams', { title: title, source: source, link: link, platform: platform })
  end
  
  private
  
  def get(path, params = {})
    uri = URI("#{API_BASE}#{path}")
    uri.query = URI.encode_www_form(params) unless params.empty?
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@token}" if @token
    
    execute_request(uri, request)
  end
  
  def post(path, body)
    uri = URI("#{API_BASE}#{path}")
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@token}" if @token
    request.body = body.to_json
    
    execute_request(uri, request)
  end
  
  def execute_request(uri, request)
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    
    JSON.parse(response.body)
  end
end
```

### Python

```python
import requests
import json

class StreamSourceAPI:
    def __init__(self, base_url='http://localhost:3000/api/v1'):
        self.base_url = base_url
        self.token = None
    
    def login(self, email, password):
        response = requests.post(
            f'{self.base_url}/users/login',
            json={'email': email, 'password': password}
        )
        data = response.json()
        self.token = data.get('token')
        return data
    
    def get_streams(self, **params):
        headers = {'Authorization': f'Bearer {self.token}'}
        response = requests.get(
            f'{self.base_url}/streams',
            headers=headers,
            params=params
        )
        return response.json()
    
    def create_stream(self, title, source, link, platform='youtube'):
        headers = {
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json'
        }
        response = requests.post(
            f'{self.base_url}/streams',
            headers=headers,
            json={'title': title, 'source': source, 'link': link, 'platform': platform}
        )
        return response.json()

# Usage
api = StreamSourceAPI()
api.login('user@example.com', 'SecurePass123')
streams = api.get_streams(status='live', per_page=50)
new_stream = api.create_stream('My Stream', 'YouTube', 'https://example.com/stream', 'youtube')
```

## Postman Collection

Import this collection to test the API in Postman:

```json
{
  "info": {
    "name": "StreamSource API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    {
      "key": "base_url",
      "value": "http://localhost:3000/api/v1"
    },
    {
      "key": "token",
      "value": ""
    }
  ],
  "item": [
    {
      "name": "Authentication",
      "item": [
        {
          "name": "Sign Up",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"test@example.com\",\n  \"password\": \"TestPass123\",\n  \"role\": \"editor\"\n}"
            },
            "url": "{{base_url}}/users/signup"
          }
        },
        {
          "name": "Login",
          "event": [
            {
              "listen": "test",
              "script": {
                "exec": [
                  "var jsonData = pm.response.json();",
                  "pm.collectionVariables.set(\"token\", jsonData.token);"
                ]
              }
            }
          ],
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"test@example.com\",\n  \"password\": \"TestPass123\"\n}"
            },
            "url": "{{base_url}}/users/login"
          }
        }
      ]
    },
    {
      "name": "Streams",
      "item": [
        {
          "name": "List Streams",
          "request": {
            "method": "GET",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              }
            ],
            "url": {
              "raw": "{{base_url}}/streams?status=active&per_page=10",
              "host": ["{{base_url}}"],
              "path": ["streams"],
              "query": [
                {
                  "key": "status",
                  "value": "active"
                },
                {
                  "key": "per_page",
                  "value": "10"
                }
              ]
            }
          }
        },
        {
          "name": "Create Stream",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              },
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"title\": \"Test Stream\",\n  \"source\": \"YouTube\",\n  \"link\": \"https://example.com/test\",\n  \"platform\": \"youtube\"\n}"
            },
            "url": "{{base_url}}/streams"
          }
        }
      ]
    }
  ]
}
```

## Support

For issues or questions:
- Check the error message for specific validation failures
- Verify your authentication token is valid and not expired
- Ensure you have the correct role for the operation
- Check rate limit headers if receiving 429 errors
- Review the health endpoints for system status