# Quick Reference Guide

## Common Commands

### Development with Docker

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f web

# Access Rails console
docker compose exec web bundle exec rails console

# Run migrations
docker compose exec web bundle exec rails db:migrate

# Run tests
docker compose exec web bundle exec rspec

# Build assets
docker compose exec web yarn build
docker compose exec web yarn build:css

# Stop all services
docker compose down
```

### Database Operations

```bash
# Create and setup database
docker compose exec web bundle exec rails db:setup

# Run migrations
docker compose exec web bundle exec rails db:migrate

# Rollback migration
docker compose exec web bundle exec rails db:rollback

# Reset database (drop, create, migrate, seed)
docker compose exec web bundle exec rails db:reset

# Access PostgreSQL console
docker compose exec db psql -U streamsource streamsource_development
```

### Testing

```bash
# Run all tests
docker compose exec web bundle exec rspec

# Run specific test file
docker compose exec web bundle exec rspec spec/models/user_spec.rb

# Run with coverage
docker compose exec web COVERAGE=true bundle exec rspec

# Run specific test by line number
docker compose exec web bundle exec rspec spec/models/user_spec.rb:42
```

### Code Quality

```bash
# Run linter
docker compose exec web bundle exec rubocop

# Auto-fix linting issues
docker compose exec web bundle exec rubocop -A

# Security audit
docker compose exec web bundle audit

# Check for outdated gems
docker compose exec web bundle outdated
```

## API Endpoints

### Public Endpoints
- `POST /api/v1/users/signup` - Create account
- `POST /api/v1/users/login` - Get JWT token
- `GET /health` - Health check
- `GET /health/live` - Liveness probe
- `GET /health/ready` - Readiness probe
- `GET /api-docs` - Swagger documentation

### Protected Endpoints (require JWT)
- `GET /api/v1/streams` - List streams
- `GET /api/v1/streams/:id` - Get stream
- `POST /api/v1/streams` - Create stream (editor/admin)
- `PATCH /api/v1/streams/:id` - Update stream (owner/admin)
- `DELETE /api/v1/streams/:id` - Delete stream (owner/admin)
- `PUT /api/v1/streams/:id/pin` - Pin stream
- `DELETE /api/v1/streams/:id/pin` - Unpin stream

### Feature-Flagged Endpoints
- `GET /api/v1/streams/:id/analytics` - Stream analytics
- `GET /api/v1/streams/export` - Export streams
- `POST /api/v1/streams/bulk_import` - Bulk import

## Admin Interface

### URLs
- `/admin` - Admin dashboard (redirects to streams)
- `/admin/login` - Admin login page
- `/admin/streams` - Manage streams
- `/admin/users` - Manage users
- `/admin/feature_flags` - Feature flags

### Default Credentials (Development)
- Email: `admin@example.com`
- Password: `password123`

## Quick Debugging

### Check JWT Token
```ruby
# In Rails console
token = "your.jwt.token"
payload = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256')
puts payload
```

### Test API Authentication
```bash
# Login and save token
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "password123"}' | jq -r '.token')

# Use token
curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/api/v1/streams
```

### View Rails Routes
```bash
# All routes
docker compose exec web bundle exec rails routes

# Filter routes
docker compose exec web bundle exec rails routes | grep stream

# Routes for specific controller
docker compose exec web bundle exec rails routes -c streams
```

### Clear Rate Limits
```bash
# In development (restart to clear memory store)
docker compose restart web

# In production (clear Redis)
docker compose exec redis redis-cli
> KEYS rack::attack* | xargs DEL
```

### Debug JavaScript
```javascript
// In browser console

// Check if Turbo is working
Turbo.session.drive

// List Stimulus controllers
Stimulus.controllers

// Debug specific controller
Stimulus.controllers.find(c => c.constructor.name === "ModalController")
```

## Environment Variables

### Required
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string  
- `SECRET_KEY_BASE` - Rails secret key

### Optional
- `RAILS_ENV` - Environment (development/test/production)
- `RAILS_LOG_TO_STDOUT` - Log to stdout (true/false)
- `WEB_CONCURRENCY` - Number of Puma workers
- `RAILS_MAX_THREADS` - Max threads per worker

## Troubleshooting

### Container Issues
```bash
# Rebuild containers
docker compose build --no-cache web

# Remove all containers and volumes
docker compose down -v

# Check container logs
docker compose logs web | tail -100
```

### Asset Problems
```bash
# Rebuild all assets
docker compose exec web yarn build
docker compose exec web yarn build:css

# Check asset files
docker compose exec web ls -la public/assets/

# Clear asset cache
docker compose exec web rm -rf app/assets/builds/*
docker compose exec web yarn build && yarn build:css
```

### Database Connection Error
```bash
# Check PostgreSQL is running
docker compose ps db

# Test connection
docker compose exec db pg_isready -U streamsource

# Check database exists
docker compose exec db psql -U streamsource -l
```

### Bundle/Gem Issues
```bash
# Install missing gems
docker compose exec web bundle install

# Update gems
docker compose exec web bundle update

# Check gem location
docker compose exec web bundle show <gem-name>
```

### Tests Failing
```bash
# Reset test database
docker compose exec web RAILS_ENV=test bundle exec rails db:reset

# Run single test with details
docker compose exec web bundle exec rspec path/to/spec.rb --format documentation

# Check test logs
docker compose exec web tail -f log/test.log
```

## Performance Tips

### Database Queries
```ruby
# Use includes to avoid N+1
Stream.includes(:user).where(status: 'active')

# Use pluck for single columns
User.where(role: 'admin').pluck(:email)

# Use select for specific columns
Stream.select(:id, :name, :url).where(user_id: user.id)
```

### Caching
```ruby
# Cache expensive operations
Rails.cache.fetch("user_streams/#{user.id}", expires_in: 1.hour) do
  user.streams.active.to_a
end

# Clear cache
Rails.cache.clear
```

### Background Jobs (Ready for Sidekiq)
```ruby
# When implemented, use for:
# - Email sending
# - Export generation
# - Analytics processing
# - Bulk operations
```

## Security Checklist

- [ ] Never commit `.env` or credentials
- [ ] Use strong params in controllers
- [ ] Authorize all actions with Pundit policies
- [ ] Validate all user inputs
- [ ] Keep dependencies updated (`bundle audit`)
- [ ] Use HTTPS in production
- [ ] Configure CORS properly
- [ ] Monitor rate limiting
- [ ] Review logs regularly
- [ ] Rotate secrets periodically

## Git Workflow

```bash
# Create feature branch
git checkout -b feature/your-feature

# Run tests before committing
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rubocop

# Commit with descriptive message
git add .
git commit -m "Add feature: description"

# Push and create PR
git push origin feature/your-feature
```

## Useful Rails Commands

```bash
# Generate migration
docker compose exec web bundle exec rails generate migration AddFieldToModel field:type

# Generate model
docker compose exec web bundle exec rails generate model ModelName field:type

# Rails console shortcuts
# c - continue
# n - next line
# s - step into
# reload! - reload console

# View middleware stack
docker compose exec web bundle exec rails middleware

# View initializers
docker compose exec web bundle exec rails initializers
```