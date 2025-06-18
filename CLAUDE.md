# Claude AI Assistant Context

This document provides context and guidelines for AI assistants (particularly Claude) working on the StreamSource API project.

## 🚨 CRITICAL: Docker-Only Development 🚨

**This project runs EXCLUSIVELY in Docker containers. Do NOT use system Ruby, Bundler, or any host machine tools.**

Quick start:
```bash
# Start everything
docker-compose up -d

# Run any command
docker-compose exec web [command]

# Examples:
docker-compose exec web bin/test
docker-compose exec web bin/rails console
docker-compose exec web bundle exec rubocop
```

## Project Overview

StreamSource is a Rails 8 application providing both a RESTful API and an admin web interface for managing streaming sources. It was migrated from a Node.js/Express application to Rails, implementing modern security practices, comprehensive testing, and a real-time admin interface using Hotwire.

## Key Technical Details

### Architecture
- **Rails 8.0.2** with API + Admin interface
- **PostgreSQL 15** for data persistence
- **Redis 7** for caching, sessions, and rate limiting
- **JWT** for API authentication
- **Session-based auth** for admin interface
- **Hotwire** (Turbo + Stimulus) for real-time UI
- **Tailwind CSS** for styling
- **Docker** for containerization

### Code Organization
- Thin controllers with business logic in models
- Authorization separated into Pundit policies
- Constants centralized in `config/application_constants.rb`
- Comprehensive test coverage (target: 100%)

### Authentication & Authorization
- **API**: JWT tokens with 24-hour expiration
- **Admin**: Session-based authentication
- Three roles: default, editor, admin
- Role-based permissions:
  - **default**: Can view streams only
  - **editor**: Can create/edit/delete own streams
  - **admin**: Full access to all resources + admin interface

### Important Patterns
1. **Error Handling**: Centralized in BaseController
2. **Pagination**: Default 25 items, max 100 (Pagy in admin)
3. **Rate Limiting**: Configured in Rack::Attack
4. **Serialization**: ActiveModel::Serializers for API
5. **Real-time updates**: Turbo Streams for admin interface
6. **Feature flags**: Flipper for gradual rollouts
7. **Asset pipeline**: ESBuild + Tailwind CSS

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
1. Create migration: `bin/rails generate migration AddFieldToModel`
2. Update model validations and associations
3. Update serializers if needed
4. Update tests
5. Run migration: `bin/rails db:migrate`

### API Endpoint Addition
1. Add route in `config/routes.rb`
2. Create controller action
3. Add authorization policy
4. Write request specs
5. Update API documentation

## Testing Guidelines

### Running Tests
```bash
# All tests (automatically sets RAILS_ENV=test and prepares database)
docker-compose exec web bin/test

# Specific file
docker-compose exec web bin/test spec/models/user_spec.rb

# Run tests at specific line
docker-compose exec web bin/test spec/models/user_spec.rb:42

# With coverage report
docker-compose exec web bin/test

# Note: The bin/test wrapper automatically:
# - Sets RAILS_ENV=test
# - Prepares the test database
# - Runs tests with proper configuration
```

### Test Structure
- Unit tests for models
- Controller tests for endpoints
- Request specs for integration
- Policy specs for authorization
- Always test edge cases

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

## Essential Docker Commands

**Remember**: ALL commands must be run through Docker. Never use local/system tools.

```bash
# Start services (do this first!)
docker-compose up -d

# Verify services are running
docker-compose ps

# Build assets
docker-compose exec web yarn build
docker-compose exec web yarn build:css

# Run migrations
docker-compose exec web bin/rails db:migrate

# Access Rails console
docker-compose exec web bin/rails console

# Run tests (uses bin/test wrapper)
docker-compose exec web bin/test

# Run specific tests
docker-compose exec web bin/test spec/models/stream_spec.rb

# View logs
docker-compose logs -f web

# Rebuild after Gemfile changes
docker-compose build web
docker-compose restart web

# Stop all services
docker-compose down

# Remove all data and start fresh
docker-compose down -v
docker-compose up -d
```

## Common Issues & Solutions

### JWT Token Issues
- Tokens expire after 24 hours
- Use `ApplicationConstants::JWT::ALGORITHM` for consistency
- Secret key from `Rails.application.secret_key_base`

### Rate Limiting
- Development uses memory store
- Production uses Redis
- Clear with: `docker-compose exec redis redis-cli FLUSHALL`

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

## Deployment Checklist

1. Run tests: `docker-compose exec web bin/test`
2. Check code style: `docker-compose exec web bundle exec rubocop`
3. Update documentation
4. Set environment variables
5. Run migrations in production
6. Verify health checks work
7. Monitor rate limiting
8. Check error tracking

## AI Assistant Guidelines

When working on this project:

1. **Prioritize tests** - Always write/update tests for changes
2. **Follow patterns** - Maintain consistency with existing code
3. **Document changes** - Update README and inline comments
4. **Consider security** - Validate input, authorize actions
5. **Think about performance** - Pagination, caching, indexes
6. **Use constants** - Add to ApplicationConstants module
7. **Keep it simple** - Avoid over-engineering
8. **Always run unit tests before finishing your work**

## Migration from Node.js

This project was migrated from a Node.js/Express application. Key differences:

1. **ORM**: Sequelize → ActiveRecord
2. **Auth**: Passport → JWT with custom implementation
3. **Testing**: Jest → RSpec
4. **Validation**: Express-validator → ActiveModel validations
5. **Rate Limiting**: express-rate-limit → Rack::Attack

## Future Enhancements

Potential areas for improvement:

1. **GraphQL API** - Alternative to REST
2. **WebSocket Support** - Real-time updates
3. **Background Jobs** - Sidekiq integration
4. **File Uploads** - Active Storage
5. **API Versioning** - Beyond v1
6. **Caching Layer** - Redis caching
7. **Search** - Elasticsearch integration
8. **Monitoring** - APM integration

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
4. **Isolation**: Prevents conflicts with other projects on your machine

### Never Do This:
```bash
# ❌ WRONG - Don't use system commands
bundle install
rails server
rspec

# ✅ CORRECT - Always use Docker
docker-compose exec web bundle install
docker-compose exec web bin/rails server
docker-compose exec web bin/test
```