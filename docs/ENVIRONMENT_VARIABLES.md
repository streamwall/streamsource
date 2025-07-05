# StreamSource Environment Variables Documentation

This document provides comprehensive documentation for all environment variables used in the StreamSource application.

## Table of Contents

1. [Overview](#overview)
2. [Required Variables](#required-variables)
3. [Optional Variables](#optional-variables)
4. [Environment-Specific Variables](#environment-specific-variables)
5. [Docker Variables](#docker-variables)
6. [Security Best Practices](#security-best-practices)

## Overview

StreamSource uses environment variables for configuration to follow the [12-factor app](https://12factor.net/config) methodology. Environment variables are loaded from `.env` files in development and from system environment in production.

### Loading Order

1. System environment variables (highest priority)
2. `.env.production` (production only)
3. `.env.development` (development only)
4. `.env` (all environments)
5. Defaults in code (lowest priority)

## Required Variables

These variables MUST be set for the application to function properly:

### `SECRET_KEY_BASE`
- **Purpose**: Rails secret key for encrypting sessions and cookies
- **Generate**: `rails secret` or `openssl rand -hex 64`
- **Example**: `a7b9c3d4e5f6789...` (128 hex characters)
- **Security**: NEVER share or commit this value

### `DATABASE_URL`
- **Purpose**: PostgreSQL connection string
- **Format**: `postgres://username:password@host:port/database`
- **Example**: `postgres://streamsource:password@localhost:5432/streamsource_production`
- **Notes**: Overrides database.yml settings

### `REDIS_URL`
- **Purpose**: Redis connection for ActionCable, caching, and sessions
- **Format**: `redis://host:port/database`
- **Example**: `redis://localhost:6379/0`
- **Default**: `redis://localhost:6379/0`

## Optional Variables

### Core Rails Configuration

#### `RAILS_ENV`
- **Purpose**: Rails environment mode
- **Values**: `development`, `test`, `production`
- **Default**: `development`

#### `RAILS_LOG_TO_STDOUT`
- **Purpose**: Output logs to stdout instead of files
- **Values**: `true`, `false`
- **Default**: `false` (true in Docker)
- **Recommended**: `true` for production

#### `RAILS_LOG_LEVEL`
- **Purpose**: Minimum log level to record
- **Values**: `debug`, `info`, `warn`, `error`, `fatal`
- **Default**: `debug` (development), `info` (production)

#### `RAILS_SERVE_STATIC_FILES`
- **Purpose**: Serve static assets from Rails
- **Values**: `true`, `false`
- **Default**: `false`
- **Notes**: Set to `true` if not using nginx/CDN for assets

#### `RAILS_MASTER_KEY`
- **Purpose**: Key for decrypting credentials.yml.enc
- **Notes**: Alternative to config/master.key file

### Application Server

#### `RAILS_MAX_THREADS`
- **Purpose**: Maximum threads per Puma worker
- **Default**: `5`
- **Notes**: Also controls database connection pool size

#### `WEB_CONCURRENCY`
- **Purpose**: Number of Puma worker processes
- **Default**: `2`
- **Recommendations**:
  - 1GB RAM: 2 workers
  - 2GB RAM: 3-4 workers
  - 4GB RAM: 5-8 workers

#### `PORT`
- **Purpose**: Port for web server
- **Default**: `3000`
- **Notes**: Not used when binding to unix socket

#### `PIDFILE`
- **Purpose**: Location of Puma PID file
- **Default**: `tmp/pids/server.pid`

### Domain & Security

#### `APPLICATION_HOST`
- **Purpose**: Primary domain name (without protocol)
- **Example**: `streamsource.example.com`
- **Used for**: Email links, CORS, webhooks

#### `FORCE_SSL`
- **Purpose**: Force all connections over HTTPS
- **Values**: `true`, `false`
- **Default**: `true` (production)
- **Recommended**: Always `true` in production

### ActionCable WebSockets

#### `ACTION_CABLE_URL`
- **Purpose**: WebSocket endpoint URL
- **Format**: `wss://domain.com/cable`
- **Example**: `wss://streamsource.example.com/cable`

#### `ACTION_CABLE_ALLOWED_REQUEST_ORIGINS`
- **Purpose**: Allowed origins for WebSocket connections
- **Format**: Comma-separated list
- **Example**: `https://streamsource.example.com,https://www.streamsource.example.com`

### External Services

#### Error Tracking

##### `SENTRY_DSN`
- **Purpose**: Sentry error tracking endpoint
- **Format**: `https://key@sentry.io/project-id`
- **Provider**: [Sentry](https://sentry.io) (free tier available)

#### Email Configuration

##### `SMTP_ADDRESS`
- **Purpose**: SMTP server hostname
- **Examples**:
  - SendGrid: `smtp.sendgrid.net`
  - AWS SES: `email-smtp.us-east-1.amazonaws.com`
  - Postmark: `smtp.postmarkapp.com`

##### `SMTP_PORT`
- **Purpose**: SMTP server port
- **Common values**: `25`, `587` (TLS), `465` (SSL)
- **Default**: `587`

##### `SMTP_USERNAME`
- **Purpose**: SMTP authentication username
- **Notes**: For SendGrid, use `apikey` as username

##### `SMTP_PASSWORD`
- **Purpose**: SMTP authentication password
- **Security**: Use API keys when possible

##### `SMTP_DOMAIN`
- **Purpose**: HELO domain for SMTP
- **Example**: `streamsource.example.com`

### Feature Flags

These can be set via environment or managed through Flipper UI at `/admin/feature_flags`:

- `ENABLE_ANALYTICS` - Stream analytics features
- `ENABLE_BULK_IMPORT` - Bulk data import
- `ENABLE_EXPORT` - Data export functionality
- `ENABLE_WEBHOOKS` - Webhook notifications
- `ENABLE_TWO_FACTOR_AUTH` - 2FA for users
- `ENABLE_API_KEYS` - API key management
- `ENABLE_ACTIVITY_LOG` - User activity tracking
- `ENABLE_REAL_TIME_NOTIFICATIONS` - Live notifications

### Performance Monitoring

#### `NEW_RELIC_LICENSE_KEY`
- **Purpose**: New Relic APM license
- **Provider**: [New Relic](https://newrelic.com)

#### `SKYLIGHT_AUTHENTICATION`
- **Purpose**: Skylight performance monitoring
- **Provider**: [Skylight](https://skylight.io)

#### `HONEYBADGER_API_KEY`
- **Purpose**: Honeybadger error tracking
- **Provider**: [Honeybadger](https://honeybadger.io)

## Environment-Specific Variables

### Development Only

#### `BUNDLE_WITHOUT`
- **Purpose**: Exclude gem groups
- **Default**: `"production"`
- **Docker default**: `""` (empty)

### Test Only

#### `CI`
- **Purpose**: Indicate CI environment
- **Effect**: Enables eager loading in tests

### Production Only

#### `DB_PASSWORD`
- **Purpose**: Database password for backup scripts
- **Notes**: Should match password in DATABASE_URL

## Docker Variables

These are used in docker-compose.yml:

### PostgreSQL Container

- `POSTGRES_USER`: Database username (default: `streamsource`)
- `POSTGRES_PASSWORD`: Database password
- `POSTGRES_DB`: Database name

### Redis Container

No additional configuration needed.

## Security Best Practices

### 1. Secret Generation

```bash
# Generate secure secrets
rails secret                    # For SECRET_KEY_BASE
openssl rand -hex 32           # For API keys
pwgen -s 32 1                  # For passwords
```

### 2. Never Commit Secrets

Add to `.gitignore`:
```
.env
.env.*
!.env.example
!.env.*.template
```

### 3. Use Different Values Per Environment

- Never reuse development secrets in production
- Rotate secrets regularly
- Use strong, unique passwords

### 4. Secure Storage

- Production: Use environment variables or secret management service
- Development: Use `.env` files with restricted permissions
- CI/CD: Use encrypted secrets (GitHub Secrets, etc.)

### 5. Minimal Permissions

```bash
# Restrict .env file access
chmod 600 .env.production
chown deploy:deploy .env.production
```

### 6. Regular Audits

- Review environment variables quarterly
- Remove unused variables
- Update deprecated settings
- Check for exposed secrets in logs

## Troubleshooting

### Variable Not Loading

1. Check file permissions
2. Verify file location
3. Check for typos in variable names
4. Ensure no spaces around `=`
5. Restart application after changes

### Common Issues

**DATABASE_URL not working**
- Ensure format is correct
- Check network connectivity
- Verify credentials

**ActionCable not connecting**
- Verify ACTION_CABLE_URL protocol (wss:// for HTTPS)
- Check ALLOWED_REQUEST_ORIGINS includes your domain
- Ensure Redis is running

**Assets not loading**
- Set RAILS_SERVE_STATIC_FILES=true
- Or configure nginx to serve /public
- Check asset compilation succeeded

## Examples

### Minimal Production Setup

```bash
RAILS_ENV=production
SECRET_KEY_BASE=your-generated-secret
DATABASE_URL=postgres://user:pass@localhost/db
REDIS_URL=redis://localhost:6379/0
APPLICATION_HOST=example.com
```

### Full Production Setup

See `deploy/.env.production.template` for a complete example with all optional services configured.

## References

- [Rails Guides: Configuring Rails Applications](https://guides.rubyonrails.org/configuring.html)
- [12 Factor App: Config](https://12factor.net/config)
- [Puma Configuration](https://puma.io/puma/Puma/DSL.html)
- [ActionCable Configuration](https://guides.rubyonrails.org/action_cable_overview.html#configuration)