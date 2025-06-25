# Claude AI Assistant Context

This document provides context and guidelines for AI assistants (particularly Claude) working on the StreamSource API project.

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

StreamSource is a Rails 8 application providing both a RESTful API and an admin web interface for managing streamers and their streaming sources. It was migrated from a Node.js/Express application to Rails, implementing modern security practices, comprehensive testing, and a real-time admin interface using Hotwire with ActionCable WebSocket support.

The application includes advanced features for managing streamers, their platform accounts, timestamps (event annotations), and collaborative real-time editing capabilities. Recent updates have simplified the data model by removing the Notes and StreamUrl models.

## Project Resources and Documentation

- This project contains reference docs for Rails, Stimulus, Hotwire, and other vendor libraries in its vendor/docs directory. Reference these docs to assist with implementing correct and best practice solutions.

## Current Data Models

1. **User** - Authentication and authorization
   - Roles: default, editor, admin
   - JWT authentication for API, session-based for admin
   - Flipper actor support for feature flags

2. **Streamer** - Content creators
   - Belongs to a user
   - Has many streamer accounts and streams
   - Name normalization and search capabilities

3. **StreamerAccount** - Platform-specific accounts
   - Platforms: TikTok, Facebook, Twitch, YouTube, Instagram, Other
   - Auto-generates profile URLs for supported platforms

4. **Stream** - Individual streaming sessions  
   - Belongs to user and optionally to a streamer
   - Features: pinning, archiving, real-time status tracking
   - Broadcasts updates via ActionCable
   - Smart stream continuation (30-minute window)

5. **Timestamp** - Event annotations/incidents
   - Links to multiple streams via TimestampStream join table
   - Used for marking specific events or incidents

## Key Features

### API Features
- JWT authentication with 24-hour token expiration
- RESTful endpoints for streams, streamers, timestamps
- Rate limiting via Rack::Attack
- Feature-flagged endpoints: analytics, bulk import, export
- Swagger/OpenAPI documentation at `/api-docs`

### Admin Interface
- Real-time collaborative editing with ActionCable
- Cell-level locking for concurrent editing
- User presence tracking with color coding
- Turbo Streams for live UI updates
- Feature flag management via Flipper UI

### Real-time Collaboration
- CollaborativeStreamsChannel for WebSocket communication
- Redis-backed cell locking and presence
- Automatic unlock on disconnect
- Edit timeout management (5 seconds)

### Security & Infrastructure
- Comprehensive rate limiting
- Password complexity requirements
- Health check endpoints for Kubernetes
- Structured logging with Lograge
- Prometheus metrics endpoint

## Common Commands

```bash
# Development
docker compose exec web bin/rails console
docker compose exec web bin/rails server
docker compose exec web bin/rails db:migrate

# Testing
docker compose exec web bin/test
docker compose exec web bin/test spec/models/
docker compose exec web bundle exec rubocop

# Asset compilation
docker compose exec web yarn build
docker compose exec web yarn build:css

# Database
docker compose exec web bin/rails db:reset
docker compose exec db psql -U streamsource
```

## Feature Flags

Managed via Flipper, accessible at `/admin/feature_flags` when logged in as admin.

Key flags:
- Stream features: analytics, bulk_import, export, webhooks
- User features: two_factor_auth, api_keys, activity_log
- System features: maintenance_mode, real_time_notifications
- Experimental: ai_stream_recommendations, collaborative_playlists

## Testing Approach

- Full test coverage with RSpec
- Request specs for integration testing
- Policy specs for authorization
- Model specs with factories
- WebMock for external API calls
- SimpleCov for coverage reports

## Important Notes

1. **Docker is mandatory** - Never use system Ruby or Bundler
2. **Recent model removals** - Notes and StreamUrl models were removed
3. **Real-time features** - ActionCable powers collaborative editing
4. **Dual authentication** - JWT for API, sessions for admin interface
5. **Smart stream management** - Automatic continuation and archiving logic

## Development Workflow

1. Always work within Docker containers
2. Run tests before committing changes
3. Use feature flags for new features
4. Follow Rails conventions and patterns
5. Maintain high test coverage
6. Document API changes in Swagger specs

## Useful Resources

- `/api-docs` - Interactive API documentation
- `/admin` - Admin interface (requires login)
- `spec/` - Test examples and patterns
- `config/application_constants.rb` - System-wide constants
- `vendor/docs/` - Reference documentation for libraries