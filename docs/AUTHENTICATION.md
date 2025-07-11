# StreamSource Authentication Guide

## Overview

StreamSource uses **Devise with JWT tokens** for API authentication and **session-based authentication** for the admin web interface. This document covers both authentication methods and service account setup.

## Authentication Methods

### 1. API Authentication (JWT)

The API uses JWT (JSON Web Tokens) for stateless authentication:

- **Token Expiration**: 24 hours for regular users, 30 days for service accounts
- **Endpoint**: `POST /api/v1/login`
- **Token Usage**: Include in `Authorization: Bearer <token>` header

#### Login Request
```bash
curl -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "user@example.com",
      "password": "Password123!"
    }
  }'
```

#### Login Response
```json
{
  "status": {
    "code": 200,
    "message": "Logged in successfully."
  },
  "user": {
    "id": 1,
    "email": "user@example.com",
    "role": "admin",
    "created_at": "2025-01-01T00:00:00.000Z",
    "updated_at": "2025-01-01T00:00:00.000Z"
  },
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIi..."
}
```

#### Using JWT Token
```bash
curl -X GET http://localhost:3000/api/v1/streams \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIi..."
```

### 2. Admin Interface Authentication (Sessions)

The admin interface uses traditional session-based authentication:

- **Login Page**: `/admin/login`
- **Session Duration**: Configurable via Devise settings
- **CSRF Protection**: Enabled for all forms

## User Roles and Permissions

### Role Hierarchy
1. **admin** - Full system access
2. **editor** - Can create/edit streams and manage content
3. **default** - Read-only access to streams

### API Permissions Matrix

| Endpoint | Default | Editor | Admin |
|----------|---------|--------|-------|
| `GET /api/v1/streams` | ✅ | ✅ | ✅ |
| `POST /api/v1/streams` | ❌ | ✅ | ✅ |
| `PUT /api/v1/streams/:id` | ❌ | ✅ | ✅ |
| `DELETE /api/v1/streams/:id` | ❌ | ❌ | ✅ |
| `GET /api/v1/ignore_lists` | ❌ | ❌ | ✅ |
| `POST /api/v1/ignore_lists` | ❌ | ❌ | ✅ |

## Service Accounts

### What are Service Accounts?

Service accounts are special user accounts designed for automated services:

- **Longer Token Expiry**: 30 days instead of 24 hours
- **Service Identification**: JWT contains `service_account: true` flag
- **Editor Permissions**: Appropriate access level for most automation
- **Audit Trail**: Clear identification in logs and data

### Default Service Accounts

Two service accounts are created by default:

1. **livestream-monitor@streamsource.local** - For livestream-link-monitor service
2. **livesheet-updater@streamsource.local** - For livesheet-updater service

### Creating Service Accounts

#### Via Rake Tasks (Recommended)
```bash
# Create default service accounts for livestream-monitor and livesheet-updater
docker compose exec web bin/rails service_accounts:setup

# List existing service accounts
docker compose exec web bin/rails service_accounts:list

# Generate token information for service accounts
docker compose exec web bin/rails service_accounts:generate_tokens
```

#### Via Rails Console
```ruby
# Create a custom service account
service_user = User.create!(
  email: 'my-service@streamsource.local',
  password: 'SecurePassword123!',
  role: 'editor',
  is_service_account: true
)
```

### Managing Admin Users

```bash
# Create a new admin user
docker compose exec web bin/rails admin:create EMAIL=admin@example.com PASSWORD=SecurePass123!

# List all admin users
docker compose exec web bin/rails admin:list

# Promote an existing user to admin
docker compose exec web bin/rails admin:promote EMAIL=user@example.com

# Demote an admin to editor or default role
docker compose exec web bin/rails admin:demote EMAIL=admin@example.com ROLE=editor
```

### Testing Authentication

```bash
# Test authentication for all user types
docker compose exec web bin/rails auth:test_all

# Test role-based access control
docker compose exec web bin/rails auth:test_rbac

# Test service account authentication
docker compose exec web bin/rails auth:test_service_accounts

# Check all users and their status
docker compose exec web bin/rails auth:check_users
```

### Service Account Best Practices

1. **Use dedicated emails**: Always use `@streamsource.local` domain
2. **Strong passwords**: Use complex, randomly generated passwords
3. **Minimal permissions**: Use `editor` role unless admin access is required
4. **Environment variables**: Store credentials in environment variables
5. **Rotation**: Regularly rotate service account passwords

## Token Security

### JWT Token Structure

Service account tokens contain additional fields:
```json
{
  "sub": "1",              // User ID
  "scp": "user",           // Scope
  "aud": null,             // Audience
  "iat": 1672531200,       // Issued at
  "exp": 1675123200,       // Expiration (30 days for service accounts)
  "jti": "unique-id",      // JWT ID for revocation
  "service_account": true  // Service account flag
}
```

### Token Revocation

Tokens can be revoked by adding them to the JWT denylist:

```ruby
# In Rails console - revoke a specific token
JwtDenylist.create!(jti: 'jwt-id-here', exp: 30.days.from_now)
```

### Security Best Practices

1. **Store tokens securely**: Never log or expose JWT tokens
2. **Use HTTPS**: Always use secure connections in production
3. **Token expiration**: Implement proper token refresh logic
4. **Rate limiting**: Respect API rate limits (default: 60 requests/minute)
5. **Principle of least privilege**: Use minimum required permissions

## Integration Examples

### Node.js Service Integration

```javascript
class StreamSourceClient {
  constructor(config) {
    this.apiUrl = config.STREAMSOURCE_API_URL;
    this.email = config.STREAMSOURCE_EMAIL;
    this.password = config.STREAMSOURCE_PASSWORD;
    this.token = null;
    this.tokenExpiry = null;
  }

  async authenticate() {
    const response = await fetch(`${this.apiUrl}/api/v1/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        user: {
          email: this.email,
          password: this.password
        }
      })
    });

    const data = await response.json();
    this.token = data.token;
    
    // Service accounts get 30-day tokens
    this.tokenExpiry = Date.now() + (29 * 24 * 60 * 60 * 1000);
  }

  async request(endpoint, options = {}) {
    // Re-authenticate if token is expired
    if (!this.token || Date.now() > this.tokenExpiry) {
      await this.authenticate();
    }

    return fetch(`${this.apiUrl}${endpoint}`, {
      ...options,
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json',
        ...options.headers
      }
    });
  }
}
```

### Python Service Integration

```python
import requests
import time
from datetime import datetime, timedelta

class StreamSourceClient:
    def __init__(self, api_url, email, password):
        self.api_url = api_url
        self.email = email
        self.password = password
        self.token = None
        self.token_expiry = None

    def authenticate(self):
        response = requests.post(
            f"{self.api_url}/api/v1/login",
            json={
                "user": {
                    "email": self.email,
                    "password": self.password
                }
            }
        )
        response.raise_for_status()
        
        data = response.json()
        self.token = data['token']
        # Service accounts get 30-day tokens
        self.token_expiry = datetime.now() + timedelta(days=29)

    def request(self, method, endpoint, **kwargs):
        if not self.token or datetime.now() > self.token_expiry:
            self.authenticate()

        headers = kwargs.pop('headers', {})
        headers['Authorization'] = f'Bearer {self.token}'
        
        return requests.request(
            method,
            f"{self.api_url}{endpoint}",
            headers=headers,
            **kwargs
        )
```

## Environment Variables

### livestream-link-monitor
```bash
STREAMSOURCE_API_URL=https://api.streamsource.com
STREAMSOURCE_EMAIL=livestream-monitor@streamsource.local
STREAMSOURCE_PASSWORD=your-service-account-password
```

### livesheet-updater
```bash
STREAMSOURCE_API_URL=https://api.streamsource.com
STREAMSOURCE_EMAIL=livesheet-updater@streamsource.local
STREAMSOURCE_PASSWORD=your-service-account-password
```

## Troubleshooting

### Common Issues

#### 401 Unauthorized
- Check email/password credentials
- Verify user account exists and is active
- Ensure API URL is correct

#### 403 Forbidden
- Check user role permissions
- Verify endpoint requires appropriate role
- Ensure user is not trying to access admin-only features

#### Token Expired
- Implement automatic token refresh
- Check token expiration time
- Re-authenticate if token is expired

#### Rate Limiting (429)
- Respect rate limits (60 requests/minute default)
- Implement exponential backoff
- Check if multiple services are using same credentials

### Debug Commands

```bash
# Check user details
docker compose exec web bin/rails runner "
  user = User.find_by(email: 'user@example.com')
  puts \"Role: #{user.role}\"
  puts \"Service Account: #{user.is_service_account?}\"
  puts \"Valid Password: #{user.valid_password?('password')}\"
"

# Test API authentication
curl -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"user": {"email": "user@example.com", "password": "password"}}' \
  | jq .

# Decode JWT token (for debugging)
docker compose exec web bin/rails runner "
  require 'jwt'
  token = 'your-jwt-token-here'
  payload = JWT.decode(token, nil, false)[0]
  puts JSON.pretty_generate(payload)
"
```

## Migration from Email/Password

If you're migrating from direct email/password authentication:

1. **Update client code** to use JWT tokens
2. **Implement token refresh** logic
3. **Create service accounts** for automated services
4. **Update environment variables** with service account credentials
5. **Test authentication** thoroughly

The existing services (livestream-link-monitor and livesheet-updater) already implement proper JWT authentication patterns and can serve as examples for new integrations.