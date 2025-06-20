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

The application now includes advanced features for managing streamers, their platform accounts, stream URLs, incident annotations, and a polymorphic notes system.

## Key Technical Details

### Architecture
- **Rails 8.0.x** with API + Admin interface
- **Ruby 3.3.6** runtime
- **PostgreSQL 17.5** for data persistence
- **Redis 7** for caching, sessions, and rate limiting
- **JWT** for API authentication (custom implementation using bcrypt)
- **Session-based auth** for admin interface
- **Hotwire** (Turbo + Stimulus) with ActionCable for real-time UI
- **Tailwind CSS** for styling
- **Docker** with multi-stage builds for containerization
- **Node.js 20** for asset compilation

### Code Organization
- Thin controllers with business logic in models
- Authorization separated into Pundit policies
- Constants centralized in `config/application_constants.rb`
- Comprehensive test coverage with RSpec 6.1
- WebSocket support via ActionCable for real-time features
- Structured logging with Lograge
- N+1 query detection with Bullet in development

### Authentication & Authorization
- **API**: JWT tokens with 24-hour expiration (using Rails.application.secret_key_base)
- **Admin**: Session-based authentication with bcrypt (has_secure_password)
- Three roles: default, editor, admin
- Role-based permissions:
  - **default**: Can view streams only
  - **editor**: Can create/edit/delete own streams and related resources
  - **admin**: Full access to all resources + admin interface + Flipper UI

### Important Patterns
1. **Error Handling**: Centralized in BaseController
2. **Pagination**: Pagy for admin interface, Kaminari also available
3. **Rate Limiting**: Configured in Rack::Attack
4. **Serialization**: ActiveModel::Serializers for API
5. **Real-time updates**: Turbo Streams + ActionCable for admin interface
6. **Feature flags**: Flipper with UI for gradual rollouts
7. **Asset pipeline**: ESBuild + Tailwind CSS (via cssbundling-rails)
8. **CORS**: Rack::Cors for API access control
9. **Middleware**: Custom AdminFlipperAuth for Flipper UI authentication

## Common Tasks

### Adding New API Features
1. Start with tests (TDD approach)
2. Update models with validations
3. Add controller actions in `api/v1/`
4. Create/update policies for authorization
5. Add serializers for JSON output
6. Update API documentation
7. Add integration tests

### Adding Admin Interface Features
1. Create controller in `admin/` namespace
2. Add routes with HTML format support
3. Create views using Turbo Frames
4. Add Stimulus controllers for interactivity
5. Style with Tailwind CSS classes
6. Test with system specs

### Database Changes
1. Create migration: `docker compose exec web bin/rails generate migration AddFieldToModel`
2. Update model validations and associations
3. Update serializers if needed
4. Update tests
5. Run migration: `docker compose exec web bin/rails db:migrate`

### API Endpoint Addition
1. Add route in `config/routes.rb`
2. Create controller action
3. Add authorization policy
4. Write request specs
5. Update API documentation

### Data Models

#### Core Models
- **User**: Authentication and authorization
- **Stream**: Core streaming source with extensive attributes
  - Fields: title, source, link, city, state, platform, status, orientation, kind
  - Features: archiving, pinning, timestamps (started_at, ended_at)
  - Associations: belongs to user, streamer, and stream_url
- **Streamer**: Content creator management
  - Has many streams and streamer accounts
- **StreamerAccount**: Platform-specific accounts for streamers
  - Links streamers to their accounts on different platforms
- **StreamUrl**: URL management for streams
  - Tracks and validates stream URLs
- **Annotation**: Incident/event tracking system
  - Priority levels and status tracking
  - Many-to-many relationship with streams via AnnotationStream
- **Note**: Polymorphic notes system
  - Can be attached to streams or streamers
  - Belongs to users for tracking authorship

## Testing Guidelines

### Running Tests
**CRITICAL**: Always use Docker for tests. Never run tests locally.

```bash
# All tests (recommended - uses bin/test wrapper)
docker compose exec web bin/test

# Specific test file
docker compose exec web bin/test spec/models/user_spec.rb

# Specific test at line number
docker compose exec web bin/test spec/models/user_spec.rb:42

# Alternative: Run RSpec directly (must set RAILS_ENV=test)
docker compose exec -e RAILS_ENV=test web bundle exec rspec

# Check test coverage (coverage report in coverage/index.html)
docker compose exec web bin/test
```

**bin/test wrapper does:**
- Sets `RAILS_ENV=test`
- Prepares test database with `rails db:prepare`
- Runs RSpec with all arguments

### Test Types & Coverage
- **Unit tests**: Models, serializers, policies
- **Request specs**: Controller endpoints, authentication
- **System specs**: Full user workflows (when needed)
- **API Testing**: WebMock and VCR for external API interactions
- **Database Cleaner**: Configured with retry logic for Docker environments
- **SimpleCov**: Code coverage reporting (coverage report in coverage/index.html)

## Security Considerations

1. **Never commit secrets** - Use environment variables
2. **Validate all input** - Strong params in controllers
3. **Authorize all actions** - Use Pundit policies
4. **Rate limit endpoints** - Configured in Rack::Attack
5. **Sanitize output** - Use serializers

## Performance Optimization

1. **Use pagination** - Never return unlimited records
2. **Add database indexes** - For foreign keys and commonly queried fields
3. **Cache when appropriate** - Redis available for caching
4. **Optimize queries** - Use includes/joins to avoid N+1

## Code Style

1. **Follow Rubocop rules** - Run `rubocop` before committing
2. **Descriptive names** - Variables, methods, and classes
3. **Keep methods small** - Single responsibility principle
4. **Document complex logic** - Add comments for clarity
5. **Use constants** - No magic numbers or strings
6. **Hotwire conventions** - Use Turbo Frames and Streams appropriately
7. **Tailwind utilities** - Prefer utility classes over custom CSS

## Development Setup

**CRITICAL**: ALL commands must be run through Docker. Never use local Ruby/Rails/Node.

### Services in Docker Compose
- **web**: Main Rails application
- **db**: PostgreSQL 17.5 database
- **redis**: Redis 7 for caching and sessions
- **js**: JavaScript build watcher (profile: donotstart)
- **css**: CSS build watcher (profile: donotstart)

### Initial Setup
```bash
# Start all services
docker compose up -d

# Verify services are running
docker compose ps

# Run database migrations
docker compose exec web bin/rails db:migrate
```

### Daily Development
```bash
# Start services
docker compose up -d

# Run tests
docker compose exec web bin/test

# Access Rails console
docker compose exec web bin/rails console

# Run migrations after changes
docker compose exec web bin/rails db:migrate

# View application logs
docker compose logs -f web

# Watch JavaScript changes (optional)
docker compose --profile donotstart up js

# Watch CSS changes (optional)
docker compose --profile donotstart up css
```

### Asset Management
```bash
# Build JavaScript/CSS (when modified)
docker compose exec web yarn build
docker compose exec web yarn build:css

# Install new npm packages
docker compose exec web yarn add [package-name]

# After adding packages, rebuild
docker compose build web
docker compose restart web
```

### Troubleshooting
```bash
# Rebuild after Gemfile/package.json changes
docker compose build web
docker compose restart web

# Reset everything (DESTROYS ALL DATA)
docker compose down -v
docker compose up -d
docker compose exec web bin/rails db:migrate

# Stop all services
docker compose down
```

## Common Issues & Solutions

### JWT Token Issues
- Tokens expire after 24 hours
- Use `ApplicationConstants::JWT::ALGORITHM` for consistency
- Secret key from `Rails.application.secret_key_base`
- Authentication uses bcrypt (not Devise, despite gems being present)

### Rate Limiting
- Development uses memory store
- Production uses Redis
- Clear with: `docker compose exec redis redis-cli FLUSHALL`

### Database Connection
- Ensure PostgreSQL is running
- Check DATABASE_URL environment variable
- Run migrations after schema changes

## API Response Formats

### Success Response
```json
{
  "data": {
    "id": 1,
    "attribute": "value"
  }
}
```

### Error Response
```json
{
  "error": "Error message here"
}
```

### Paginated Response
```json
{
  "data": [...],
  "meta": {
    "current_page": 1,
    "total_pages": 10,
    "total_count": 250,
    "per_page": 25
  }
}
```

## AI Assistant Guidelines

When working on this project:

1. **Prioritize tests** - Always write/update tests for changes
2. **Follow patterns** - Maintain consistency with existing code
3. **Consider security** - Validate input, authorize actions
4. **Think about performance** - Pagination, caching, indexes
5. **Use constants** - Add to ApplicationConstants module
6. **Keep it simple** - Avoid over-engineering
7. **ALWAYS run tests** - `docker compose exec web bin/test` before finishing work
8. **Use Docker** - Never run commands outside Docker containers

## Migration from Node.js

This project was migrated from a Node.js/Express application. Key differences:

1. **ORM**: Sequelize → ActiveRecord
2. **Auth**: Passport → JWT with custom implementation using bcrypt
3. **Testing**: Jest → RSpec 6.1
4. **Validation**: Express-validator → ActiveModel validations
5. **Rate Limiting**: express-rate-limit → Rack::Attack
6. **Real-time**: Socket.io → ActionCable
7. **Frontend**: Express views → Hotwire (Turbo + Stimulus)

## Future Enhancements

Potential areas for improvement:

1. **GraphQL API** - Alternative to REST
2. **Enhanced WebSocket** - Expand ActionCable usage
3. **Background Jobs** - Sidekiq integration (gem already included)
4. **File Uploads** - Active Storage for media
5. **API Versioning** - Beyond v1
6. **Enhanced Caching** - Expand Redis caching strategies
7. **Search** - Elasticsearch integration
8. **Monitoring** - APM integration (Skylight ready)

## Resources

- [Rails Guides](https://guides.rubyonrails.org/)
- [JWT.io](https://jwt.io/)
- [Pundit Documentation](https://github.com/varvet/pundit)
- [RSpec Best Practices](https://www.betterspecs.org/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## Contact

For questions about architectural decisions or patterns used in this project, refer to:
- Git history for context
- Test files for usage examples
- Comments in complex code sections
- This document for high-level guidance

## Critical Docker Requirements

> **MANDATORY**: This project MUST be run exclusively within Docker containers. Do NOT use system Ruby, Bundler, or any host machine development tools. All commands, tests, and development tasks must be executed within the Docker environment.

### Why Docker-Only?
1. **Consistency**: Ensures all developers use identical environments
2. **Dependencies**: All services (PostgreSQL, Redis) are containerized
3. **Ruby Version**: The project uses Ruby 3.3.6 which may not match your system
4. **Node.js Version**: Requires Node.js 20 for asset compilation
5. **Isolation**: Prevents conflicts with other projects on your machine
6. **Database Cleaner**: Test suite configured specifically for Docker environments

### Never Do This:
```bash
# ❌ WRONG - Don't use system commands
bundle install
rails server
rspec

# ✅ CORRECT - Always use Docker
docker compose exec web bundle install
docker compose exec web bin/rails server
docker compose exec web bin/test
```