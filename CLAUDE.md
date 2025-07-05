# Claude AI Assistant Context

This document provides context and guidelines for AI assistants (particularly Claude) working on the StreamSource project.

## 🚨 CRITICAL: Docker-Only Development 🚨

**This project runs EXCLUSIVELY in Docker containers. Do NOT use system Ruby, Bundler, or any host machine tools.**

Quick start:
```bash
# Start everything
docker compose up -d

# Run any command
docker compose exec web [command]

# Examples:
docker compose exec web bin/test
docker compose exec web bin/rails console
docker compose exec web bundle exec rubocop
```

## Project Overview

StreamSource is a Rails 8 application providing both a RESTful API and a real-time collaborative admin interface for managing streamers and their streaming sources. Originally migrated from Node.js/Express, it now features modern security practices, comprehensive testing, real-time collaboration with ActionCable, and automated deployment via GitHub Actions.

### Recent Updates
- Complete deployment automation with GitHub Actions
- DigitalOcean deployment guide with cost optimization
- Comprehensive environment variable documentation
- Real-time collaborative editing with cell-level locking
- Simplified data model (removed Notes and StreamUrl models)

## Architecture & Technology Stack

### Core Technologies
- **Rails 8.0.x** - Main framework
- **Ruby 3.3.6** - Programming language
- **PostgreSQL 17** - Primary database
- **Redis 7** - Caching, ActionCable, sessions
- **Puma** - Web server with multi-worker support
- **Docker** - Containerization (mandatory)

### Frontend Stack
- **Hotwire** - Turbo + Stimulus for real-time updates
- **Tailwind CSS 3.x** - Styling framework
- **esbuild** - JavaScript bundling
- **ActionCable** - WebSocket support

### Infrastructure & Deployment
- **GitHub Actions** - CI/CD pipeline (free tier)
- **DigitalOcean Droplet** - Production hosting ($6/month)
- **Nginx** - Reverse proxy with SSL
- **Let's Encrypt** - Free SSL certificates
- **Automated power management** - 67% cost savings

## Project Resources

### Documentation
- `/README.md` - Complete project overview
- `/DIGITALOCEAN_DEPLOYMENT_GUIDE.md` - Production deployment
- `/docs/ENVIRONMENT_VARIABLES.md` - All env vars documented
- `/api-docs` - Interactive Swagger documentation
- `/vendor/docs/` - Rails, Hotwire, Stimulus references

### Configuration Files
- `.env.example` - Development environment template
- `deploy/.env.production.template` - Production template
- `.github/workflows/` - GitHub Actions workflows
- `deploy/` - All deployment scripts and configs

## Current Data Models

1. **User** - Authentication and authorization
   - Roles: default, editor, admin
   - JWT auth for API (24-hour expiration)
   - Session auth for admin interface
   - Devise + bcrypt for security

2. **Streamer** - Content creators
   - Has many streamer accounts and streams
   - Name normalization for consistency
   - Full-text search capabilities

3. **StreamerAccount** - Platform-specific accounts
   - Platforms: TikTok, Facebook, Twitch, YouTube, Instagram, Other
   - Auto-generates profile URLs
   - Links streamers to platforms

4. **Stream** - Individual streaming sessions
   - Smart continuation (30-minute window)
   - Status: checking, live, offline, error, archived
   - Pin/unpin for highlighting
   - Real-time updates via ActionCable

5. **Timestamp** - Event annotations
   - Links to multiple streams via join table
   - Priority levels for importance
   - Time-based incident tracking

## Key Features

### API Features
- JWT authentication with Bearer tokens
- RESTful design with consistent patterns
- Comprehensive rate limiting (60 req/min default)
- Pagination with Pagy (25 items default)
- Advanced filtering and search
- Feature flags via Flipper

### Admin Interface
- **Real-time collaboration**
  - Cell-level locking prevents conflicts
  - User presence with color coding
  - 5-second edit timeout
  - Automatic unlock on disconnect
- **Turbo-powered UI**
  - Instant updates without refresh
  - Modal forms with Turbo Frames
  - Debounced search
  - Responsive design

### Security Features
- SSL/TLS enforced in production
- CORS configuration for API
- CSP headers prevent XSS
- SQL injection protection
- CSRF tokens for web forms
- Secure password requirements
- Rate limiting with Rack::Attack
- Fail2ban for SSH protection

## Development Workflow

### 1. Environment Setup
```bash
# Clone repository
git clone https://github.com/yourusername/streamsource.git
cd streamsource

# Copy environment file
cp .env.example .env

# Start services
docker compose up -d

# Check logs
docker compose logs -f web
```

### 2. Common Development Tasks
```bash
# Rails console
docker compose exec web bin/rails console

# Run tests
docker compose exec web bin/test

# Database migrations
docker compose exec web bin/rails db:migrate

# Linting
docker compose exec web bundle exec rubocop -A

# Asset compilation
docker compose exec web yarn build
docker compose exec web yarn build:css
```

### 3. Testing Guidelines
- Write tests first (TDD)
- Run full suite before commits
- Maintain high coverage (SimpleCov)
- Test edge cases and errors
- Use factories, not fixtures
- Mock external API calls

### 4. Git Workflow
```bash
# Create feature branch
git checkout -b feature/your-feature

# Make changes and test
docker compose exec web bin/test

# Commit with clear message
git commit -m "Add feature: description"

# Push and create PR
git push origin feature/your-feature
```

## Deployment

### Automated Deployment (GitHub Actions)
1. Push to main branch
2. Tests run automatically
3. If tests pass, deploys to production
4. Health check verifies deployment

### Manual Deployment
```bash
# Quick deploy after setup
make deploy HOST=your-droplet-ip

# Check status
make status HOST=your-droplet-ip

# View logs
make logs HOST=your-droplet-ip
```

### Cost Optimization
- Droplet powers off at 6 PM daily
- Powers on at 9 AM weekdays
- Saves ~$21/month (67% reduction)
- Configurable via GitHub Actions

## Feature Flags

Access at `/admin/feature_flags` when logged in as admin.

### Stream Features
- `analytics` - Advanced analytics
- `bulk_import` - Bulk data import
- `export` - Data export
- `webhooks` - Webhook notifications

### User Features
- `two_factor_auth` - 2FA support
- `api_keys` - API key management
- `activity_log` - Audit logging

### System Features
- `maintenance_mode` - Maintenance page
- `real_time_notifications` - Live alerts
- `ai_stream_recommendations` - AI features
- `collaborative_playlists` - Playlist sharing

## API Quick Reference

### Authentication
```bash
# Login
POST /api/v1/users/login
{"email": "user@example.com", "password": "Password123!"}

# Returns JWT token
{"token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."}

# Use token
GET /api/v1/streams
Authorization: Bearer YOUR_TOKEN
```

### Common Endpoints
- `GET /api/v1/streams` - List streams
- `POST /api/v1/streams` - Create stream
- `PATCH /api/v1/streams/:id` - Update stream
- `PUT /api/v1/streams/:id/pin` - Pin stream
- `POST /api/v1/streams/:id/archive` - Archive

### Filters & Pagination
```
GET /api/v1/streams?status=live&pinned=true&page=2
GET /api/v1/streamers?search=gaming&per_page=50
```

## Troubleshooting

### Common Issues

**Docker container errors**
```bash
docker compose down
docker compose up -d --build
```

**Database connection issues**
```bash
docker compose exec web bin/rails db:reset
```

**Asset compilation problems**
```bash
docker compose exec web yarn install
docker compose exec web yarn build
```

**Test failures**
```bash
docker compose exec web bin/rails db:test:prepare
docker compose exec web bin/test
```

## Important Notes

1. **Always use Docker** - Never install Ruby/Rails locally
2. **Environment variables** - Check `.env.example` for all options
3. **Feature flags** - Test new features behind flags first
4. **Real-time updates** - ActionCable requires Redis
5. **Security first** - Follow security best practices
6. **Documentation** - Update docs with code changes
7. **Test coverage** - Maintain >90% coverage
8. **Code style** - Follow RuboCop rules

## Quick Command Reference

```bash
# Start project
docker compose up -d

# Run tests
docker compose exec web bin/test

# Rails console
docker compose exec web bin/rails console

# Deploy to production
make deploy HOST=your-server

# Check deployment
make status HOST=your-server

# View production logs
make logs HOST=your-server

# Database tasks
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails db:seed
docker compose exec web bin/rails db:reset

# Linting
docker compose exec web bundle exec rubocop -A

# Asset building
docker compose exec web yarn build
docker compose exec web yarn build:css
```

## Getting Help

1. Check existing documentation in `/docs`
2. Review test files for usage examples
3. Use `bin/rails routes` to see all routes
4. Check `/api-docs` for API documentation
5. Review GitHub Actions logs for deployment issues

Remember: This project prioritizes security, testing, and documentation. When in doubt, write a test!