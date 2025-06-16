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
- `status` (optional): Filter by status (`active` or `inactive`)
- `notStatus` (optional): Exclude streams with this status
- `user_id` (optional): Filter by user ID
- `is_pinned` (optional): Filter by pin state (`true` or `false`)

**Response:**
```json
{
  "streams": [
    {
      "id": 1,
      "url": "https://example.com/stream1",
      "name": "Example Stream",
      "status": "active",
      "is_pinned": false,
      "created_at": "2024-01-01T12:00:00Z",
      "updated_at": "2024-01-01T12:00:00Z",
      "user": {
        "id": 1,
        "email": "user@example.com",
        "role": "editor",
        "created_at": "2024-01-01T12:00:00Z",
        "updated_at": "2024-01-01T12:00:00Z"
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
  "url": "https://example.com/stream1",
  "name": "Example Stream",
  "status": "active",
  "is_pinned": false,
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "editor",
    "created_at": "2024-01-01T12:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z"
  }
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
  "name": "My New Stream",
  "url": "https://example.com/new-stream",
  "status": "active"
}
```

**Parameters:**
- `name` (required): Stream name (1-255 characters)
- `url` (required): Valid HTTP or HTTPS URL
- `status` (optional): Stream status - `active` or `inactive` (defaults to `active`)

**Response:**
```json
{
  "id": 2,
  "url": "https://example.com/new-stream",
  "name": "My New Stream",
  "status": "active",
  "is_pinned": false,
  "created_at": "2024-01-01T12:30:00Z",
  "updated_at": "2024-01-01T12:30:00Z",
  "user": {
    "id": 1,
    "email": "editor@example.com",
    "role": "editor",
    "created_at": "2024-01-01T12:00:00Z",
    "updated_at": "2024-01-01T12:00:00Z"
  }
}
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
  "name": "Updated Stream Name",
  "url": "https://example.com/updated-stream",
  "status": "inactive"
}
```

**Parameters:**
- `name` (optional): New stream name
- `url` (optional): New stream URL
- `status` (optional): New status

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
  -d '{"name": "My Stream", "url": "https://example.com/stream"}'
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
  -d '{"name": "Updated Name", "status": "inactive"}'
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
async function createStream(name, url) {
  const response = await fetch(`${API_BASE}/streams`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ name, url })
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
  
  def create_stream(name, url)
    post('/streams', { name: name, url: url })
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
    
    def create_stream(self, name, url):
        headers = {
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json'
        }
        response = requests.post(
            f'{self.base_url}/streams',
            headers=headers,
            json={'name': name, 'url': url}
        )
        return response.json()

# Usage
api = StreamSourceAPI()
api.login('user@example.com', 'SecurePass123')
streams = api.get_streams(status='active', per_page=50)
new_stream = api.create_stream('My Stream', 'https://example.com/stream')
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
              "raw": "{\n  \"name\": \"Test Stream\",\n  \"url\": \"https://example.com/test\"\n}"
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