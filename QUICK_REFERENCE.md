# Quick Reference Guide

## Common Commands

### Development

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f web

# Access Rails console
docker-compose exec web bin/rails console

# Run migrations
docker-compose exec web bin/rails db:migrate

# Run tests
docker-compose exec web bundle exec rspec

# Stop all services
docker-compose down
```

### Database

```bash
# Create database
bin/rails db:create

# Run migrations
bin/rails db:migrate

# Rollback migration
bin/rails db:rollback

# Reset database
bin/rails db:reset

# Seed data
bin/rails db:seed
```

### Testing

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec

# Run specific test by line number
bundle exec rspec spec/models/user_spec.rb:42
```

### Code Quality

```bash
# Run linter
rubocop

# Auto-fix linting issues
rubocop -a

# Security audit
bundle audit

# Check for outdated gems
bundle outdated
```

## API Endpoints

### Public Endpoints
- `POST /api/v1/users/signup` - Create account
- `POST /api/v1/users/login` - Get JWT token
- `GET /health` - Health check
- `GET /health/live` - Liveness probe
- `GET /health/ready` - Readiness probe

### Protected Endpoints (require JWT)
- `GET /api/v1/streams` - List streams
- `GET /api/v1/streams/:id` - Get stream
- `POST /api/v1/streams` - Create stream (editor/admin)
- `PATCH /api/v1/streams/:id` - Update stream (owner/admin)
- `DELETE /api/v1/streams/:id` - Delete stream (owner/admin)
- `PUT /api/v1/streams/:id/pin` - Pin stream
- `DELETE /api/v1/streams/:id/pin` - Unpin stream

## Quick Debugging

### Check JWT Token
```ruby
# In Rails console
token = "your.jwt.token"
payload = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256')
puts payload
```

### Test Authentication
```bash
# Login and save token
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "Admin123!"}' | jq -r '.token')

# Use token
curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/api/v1/streams
```

### Clear Rate Limits
```bash
# In development (memory store)
docker-compose restart web

# In production (Redis)
docker-compose exec redis redis-cli FLUSHALL
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

### Bundle Install Fails
```bash
# Update bundler
gem install bundler

# Clear bundle cache
rm -rf vendor/bundle
bundle install
```

### Database Connection Error
```bash
# Check PostgreSQL is running
docker-compose ps db

# Check connection
docker-compose exec db psql -U streamsource -d streamsource_development
```

### Redis Connection Error
```bash
# Check Redis is running
docker-compose ps redis

# Test connection
docker-compose exec redis redis-cli ping
```

### Tests Failing
```bash
# Reset test database
RAILS_ENV=test bin/rails db:reset

# Clear test logs
RAILS_ENV=test bin/rails log:clear

# Run single test with output
bundle exec rspec path/to/spec.rb --format documentation
```

## Performance Tips

1. **Use includes to avoid N+1**
   ```ruby
   Stream.includes(:user).where(status: 'active')
   ```

2. **Add database indexes**
   ```ruby
   add_index :streams, [:user_id, :created_at]
   ```

3. **Use pagination**
   ```ruby
   Stream.page(params[:page]).per(25)
   ```

4. **Cache expensive operations**
   ```ruby
   Rails.cache.fetch("streams/#{user.id}", expires_in: 1.hour) do
     user.streams.active.to_a
   end
   ```

## Security Checklist

- [ ] Never commit `.env` file
- [ ] Use strong params in controllers
- [ ] Authorize all actions with Pundit
- [ ] Validate all user inputs
- [ ] Keep dependencies updated
- [ ] Run security audits regularly
- [ ] Use HTTPS in production
- [ ] Set secure headers
- [ ] Monitor rate limiting
- [ ] Review logs for anomalies