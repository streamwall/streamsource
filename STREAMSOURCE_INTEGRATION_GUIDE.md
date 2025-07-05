# StreamSource API Integration Guide

Based on my investigation, here's a comprehensive guide for integrating StreamSource as a backend for your client application.

## Overview

StreamSource provides a RESTful API with JWT authentication for managing streaming sources. Currently, the API exposes endpoints for **streams** and **user authentication**, while streamers and timestamps are managed through the admin interface.

## Step 1: Set Up Authentication

### 1. Register a User Account
```javascript
POST /api/v1/users/signup
Content-Type: application/json

{
  "email": "your-app@example.com",
  "password": "SecurePassword123!"
}
```

### 2. Obtain JWT Token
```javascript
POST /api/v1/users/login
Content-Type: application/json

{
  "email": "your-app@example.com",
  "password": "SecurePassword123!"
}

// Response:
{
  "user": { "id": 1, "email": "...", "role": "default" },
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

### 3. Store and Use Token
- Tokens expire after 24 hours
- Include in all API requests: `Authorization: Bearer <token>`

## Step 2: Design Multi-Backend Architecture

Create an abstraction layer to support multiple backends:

```javascript
// Backend interface
class StreamBackend {
  async createStream(data) { throw new Error('Not implemented'); }
  async updateStream(id, data) { throw new Error('Not implemented'); }
  async getStreams(filters) { throw new Error('Not implemented'); }
  async deleteStream(id) { throw new Error('Not implemented'); }
}

// StreamSource implementation
class StreamSourceBackend extends StreamBackend {
  constructor(apiUrl, token) {
    super();
    this.apiUrl = apiUrl;
    this.token = token;
  }

  async request(endpoint, options = {}) {
    const response = await fetch(`${this.apiUrl}${endpoint}`, {
      ...options,
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json',
        ...options.headers
      }
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || `HTTP ${response.status}`);
    }
    
    return response.json();
  }

  async createStream(data) {
    return this.request('/api/v1/streams', {
      method: 'POST',
      body: JSON.stringify({
        source: data.source,
        link: data.link,
        status: data.status || 'offline',
        platform: data.platform,
        title: data.title,
        notes: data.notes
      })
    });
  }

  async getStreams(filters = {}) {
    const params = new URLSearchParams(filters);
    return this.request(`/api/v1/streams?${params}`);
  }
}

// Google Sheets backend (existing)
class GoogleSheetsBackend extends StreamBackend {
  // Your existing implementation
}

// Backend manager
class BackendManager {
  constructor(config) {
    this.backends = {
      streamSource: new StreamSourceBackend(config.streamSource.url, config.streamSource.token),
      googleSheets: new GoogleSheetsBackend(config.googleSheets)
    };
    this.primaryBackend = config.primaryBackend || 'streamSource';
  }

  async createStream(data) {
    // Write to primary backend
    const result = await this.backends[this.primaryBackend].createStream(data);
    
    // Optionally sync to other backends
    if (this.config.syncBackends) {
      await this.syncToSecondaryBackends('create', data);
    }
    
    return result;
  }
}
```

## Step 3: Map Data Between Backends

Create mappers to handle differences between Google Sheets and StreamSource:

```javascript
class DataMapper {
  // Google Sheets to StreamSource
  sheetsToStreamSource(sheetRow) {
    return {
      source: sheetRow.streamerName,
      link: sheetRow.streamUrl,
      status: this.mapStatus(sheetRow.status),
      platform: this.detectPlatform(sheetRow.streamUrl),
      title: sheetRow.title,
      notes: sheetRow.description
    };
  }

  // StreamSource to Google Sheets
  streamSourceToSheets(stream) {
    return {
      id: stream.id,
      streamerName: stream.source,
      streamUrl: stream.link,
      status: stream.status,
      platform: stream.platform,
      title: stream.title,
      description: stream.notes,
      lastChecked: stream.last_checked_at,
      createdAt: stream.created_at
    };
  }

  detectPlatform(url) {
    if (url.includes('tiktok.com')) return 'TikTok';
    if (url.includes('facebook.com')) return 'Facebook';
    if (url.includes('twitch.tv')) return 'Twitch';
    if (url.includes('youtube.com')) return 'YouTube';
    if (url.includes('instagram.com')) return 'Instagram';
    return 'Other';
  }
}
```

## Step 4: Implement Core Operations

```javascript
class StreamManager {
  constructor(backendManager, mapper) {
    this.backend = backendManager;
    this.mapper = mapper;
  }

  async createStream(data) {
    // Validate required fields
    if (!data.source || !data.link) {
      throw new Error('Source and link are required');
    }

    // Create in StreamSource
    const stream = await this.backend.createStream(data);
    
    // Log for debugging
    console.log('Created stream:', stream);
    
    return stream;
  }

  async listStreams(filters = {}) {
    // Supported filters: status, notStatus, is_pinned, page, per_page
    const response = await this.backend.getStreams(filters);
    
    return {
      streams: response.streams,
      pagination: response.meta
    };
  }

  async updateStream(id, updates) {
    return await this.backend.updateStream(id, updates);
  }

  async pinStream(id) {
    return await this.backend.request(`/api/v1/streams/${id}/pin`, {
      method: 'PUT'
    });
  }
}
```

## Step 5: Handle Rate Limiting and Errors

```javascript
class RateLimitedBackend extends StreamSourceBackend {
  constructor(apiUrl, token) {
    super(apiUrl, token);
    this.requestQueue = [];
    this.rateLimitDelay = 100; // ms between requests
  }

  async request(endpoint, options) {
    try {
      return await super.request(endpoint, options);
    } catch (error) {
      if (error.message.includes('429')) {
        // Rate limited - retry with exponential backoff
        await this.delay(this.rateLimitDelay);
        this.rateLimitDelay *= 2;
        return this.request(endpoint, options);
      }
      throw error;
    }
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

## Step 6: Migration Strategy

### 1. Dual-Write Phase
- Continue using Google Sheets as primary
- Write new data to both backends
- Monitor for consistency

### 2. Migration Script
```javascript
async function migrateFromSheets() {
  const sheets = new GoogleSheetsBackend();
  const streamSource = new StreamSourceBackend();
  const mapper = new DataMapper();
  
  const sheetData = await sheets.getAllStreams();
  
  for (const row of sheetData) {
    const streamData = mapper.sheetsToStreamSource(row);
    try {
      await streamSource.createStream(streamData);
      console.log(`Migrated: ${streamData.source}`);
    } catch (error) {
      console.error(`Failed to migrate ${row.id}:`, error);
    }
  }
}
```

### 3. Cutover
- Switch primary backend to StreamSource
- Keep Google Sheets as read-only backup

## Step 7: Configuration

```javascript
const config = {
  backends: {
    streamSource: {
      url: process.env.STREAMSOURCE_API_URL || 'https://api.streamsource.com',
      token: process.env.STREAMSOURCE_TOKEN,
      enabled: true
    },
    googleSheets: {
      spreadsheetId: process.env.GOOGLE_SHEET_ID,
      credentials: require('./google-credentials.json'),
      enabled: true
    }
  },
  primaryBackend: 'streamSource',
  syncBackends: true,
  retryOptions: {
    maxRetries: 3,
    retryDelay: 1000
  }
};
```

## API Reference

### Authentication Endpoints

#### POST /api/v1/users/signup
Creates new user account.
- **Request Body**: `{ email: string, password: string }`
- **Response**: `{ user: object, token: string }`
- **No authentication required**

#### POST /api/v1/users/login
Authenticates existing user.
- **Request Body**: `{ email: string, password: string }`
- **Response**: `{ user: object, token: string }`
- **No authentication required**

### Stream Endpoints

All stream endpoints require JWT authentication via `Authorization: Bearer <token>` header.

#### GET /api/v1/streams
Lists all streams for authenticated user.
- **Query Parameters**:
  - `page`: Page number (default: 1)
  - `per_page`: Items per page (max: 100, default: 25)
  - `status`: Filter by stream status
  - `notStatus`: Exclude streams with specific status
  - `user_id`: Filter by specific user
  - `is_pinned`: Filter by pinned status
  - `sort`: Sort field (`name`, `-name`, `created`, `-created`)
- **Response**: `{ streams: array, meta: { current_page, total_pages, total_count, per_page } }`

#### POST /api/v1/streams
Creates new stream.
- **Request Body**:
  - Required: `source`, `link`
  - Optional: `status`, `platform`, `orientation`, `kind`, `city`, `state`, `notes`, `title`, `posted_by`
- **Response**: Stream object

#### GET /api/v1/streams/:id
Retrieves single stream details.
- **Response**: Stream object with relationships

#### PUT /api/v1/streams/:id
Updates existing stream.
- **Request Body**: Any stream fields to update
- **Response**: Updated stream object

#### DELETE /api/v1/streams/:id
Deletes stream.
- **Response**: 204 No Content

#### PUT /api/v1/streams/:id/pin
Pins a stream.
- **Response**: Updated stream object

#### DELETE /api/v1/streams/:id/pin
Unpins a stream.
- **Response**: Updated stream object

### Feature-Flagged Endpoints

These require specific feature flags to be enabled:

#### GET /api/v1/streams/:id/analytics
- **Feature Flag**: `stream_analytics`
- **Response**: Analytics data

#### POST /api/v1/streams/bulk_import
- **Feature Flag**: `stream_bulk_import`
- **Request Body**: Array of stream objects
- **Response**: Created streams

#### GET /api/v1/streams/export
- **Feature Flag**: `stream_export`
- **Query Parameters**: Same as GET /api/v1/streams
- **Response**: Export data

## Important Considerations

### 1. API Limitations
- Only streams are currently available via API
- Streamers and timestamps require admin interface access
- Feature flags control access to bulk import/export

### 2. Authentication
- Implement token refresh before 24-hour expiration
- Store tokens securely (never in code)

### 3. Rate Limits
- 1000 requests/minute general limit
- 500 login attempts per 20 minutes
- 300 signup attempts per hour
- Implement retry logic with exponential backoff

### 4. Data Consistency
- StreamSource auto-generates certain fields (timestamps)
- Platform detection is automatic based on URL
- Status transitions have business logic (30-minute continuation window)

### 5. Future-Proofing
- Monitor `/api-docs` for API updates
- Check feature flags for new capabilities
- Plan for eventual streamer/timestamp API endpoints

## Stream Object Structure

```json
{
  "id": 123,
  "source": "StreamerName",
  "link": "https://streaming-platform.com/stream",
  "status": "live",
  "is_pinned": false,
  "platform": "TikTok",
  "orientation": "portrait",
  "kind": "stream",
  "city": "New York",
  "state": "NY",
  "notes": "Additional notes",
  "title": "Stream Title",
  "posted_by": "username",
  "last_checked_at": "2025-01-05T10:00:00Z",
  "last_live_at": "2025-01-05T09:30:00Z",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-05T10:00:00Z",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "default"
  }
}
```

## Error Handling

All API errors follow a consistent format:
```json
{
  "error": "Error message here"
}
```

Common HTTP status codes:
- `401`: Unauthorized (invalid/expired token)
- `403`: Forbidden (insufficient permissions)
- `404`: Resource not found
- `422`: Validation error
- `429`: Rate limit exceeded
- `500`: Server error

This guide provides a complete integration path from your Google Sheets backend to StreamSource, with a flexible architecture that supports multiple backends. The key is the abstraction layer that allows you to switch between or combine backends as needed.