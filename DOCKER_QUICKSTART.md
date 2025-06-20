# Docker Quick Reference for StreamSource

## ⚠️ IMPORTANT: Use Docker for EVERYTHING

This project runs **exclusively** in Docker. Never use system Ruby, Bundler, or any local development tools.

## Getting Started (First Time)

```bash
# 1. Clone the repo
git clone [repository-url]
cd streamsource

# 2. Start everything
docker compose up -d

# 3. Check it's working
docker compose ps
docker compose logs -f web
```

## Daily Development Commands

### Most Common Commands

```bash
# Run tests
docker compose exec web bin/test

# Rails console
docker compose exec web bin/rails console

# View logs
docker compose logs -f web

# Run migrations
docker compose exec web bin/rails db:migrate
```

### Working with Code

```bash
# Run linter
docker compose exec web bundle exec rubocop

# Auto-fix linting issues
docker compose exec web bundle exec rubocop -A

# Run specific test file
docker compose exec web bin/test spec/models/stream_spec.rb

# Run test at specific line
docker compose exec web bin/test spec/models/stream_spec.rb:42
```

### Database Commands

```bash
# Create database
docker compose exec web bin/rails db:create

# Run migrations
docker compose exec web bin/rails db:migrate

# Rollback migration
docker compose exec web bin/rails db:rollback

# Reset database (drop, create, migrate, seed)
docker compose exec web bin/rails db:reset

# Access PostgreSQL console
docker compose exec db psql -U streamsource
```

### Asset Management

```bash
# Build JavaScript
docker compose exec web yarn build

# Build CSS
docker compose exec web yarn build:css

# Watch mode (using separate services - recommended)
docker compose --profile donotstart up js
docker compose --profile donotstart up css

# Or run directly in web container
docker compose exec web yarn build --watch
docker compose exec web yarn build:css --watch
```

### Adding Dependencies

#### New Gems
```bash
# 1. Edit Gemfile
# 2. Install in container
docker compose exec web bundle install
# 3. If it fails, rebuild
docker compose build web
docker compose restart web
```

#### New NPM Packages
```bash
# Add package
docker compose exec web yarn add [package-name]

# Add dev dependency
docker compose exec web yarn add -D [package-name]
```

### Debugging

```bash
# View Rails routes
docker compose exec web bin/rails routes

# View Rails routes for specific controller
docker compose exec web bin/rails routes -c streams

# Interactive debugging (after adding binding.pry)
docker attach streamsource-web-1

# Or use the container name
docker attach $(docker compose ps -q web)
```

## Container Management

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# Restart a specific service
docker compose restart web

# Rebuild containers (after Dockerfile changes)
docker compose build

# Start fresh (removes volumes)
docker compose down -v
docker compose up -d
```

## Common Workflows

### Creating a New Feature
```bash
# 1. Generate model
docker compose exec web bin/rails g model Feature name:string

# 2. Run migration
docker compose exec web bin/rails db:migrate

# 3. Generate controller
docker compose exec web bin/rails g controller api/v1/features

# 4. Run tests
docker compose exec web bin/test
```

### Working with the Test Database
```bash
# Prepare test database
docker compose exec -e RAILS_ENV=test web bin/rails db:prepare

# Run tests with specific seed
docker compose exec -e SEED=12345 web bin/test

# Access test database
docker compose exec db psql -U streamsource streamsource_test
```

## Troubleshooting

### Container won't start?
```bash
docker compose logs web
```

### Need to start completely fresh?
```bash
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

### Permission issues?
```bash
docker compose exec web chown -R $(id -u):$(id -g) .
```

### Out of disk space?
```bash
docker system prune -a
```

## Quick Health Checks

```bash
# Check services are running
docker compose ps

# Check web app health
curl http://localhost:3000/health

# Check database connection
docker compose exec web bin/rails db:version
```

## Accessing the Application

- **API**: http://localhost:3000
- **Admin Interface**: http://localhost:3000/admin
- **API Documentation**: http://localhost:3000/api-docs
- **Feature Flags**: http://localhost:3000/admin/feature_flags
- **Health Check**: http://localhost:3000/health
- **WebSocket**: ws://localhost:3000/cable

### Default Admin Login
- Email: `admin@example.com`
- Password: `password123`

## Key Services & Models

### New in This Version
- **Streamers**: Content creator management
- **Annotations**: Incident/event tracking
- **Stream URLs**: URL management system
- **Notes**: Polymorphic notes for documentation
- **WebSockets**: Real-time updates via ActionCable

### Running Model-Specific Commands
```bash
# Generate a new model
docker compose exec web bin/rails generate model ModelName

# Run model-specific tests
docker compose exec web bin/test spec/models/streamer_spec.rb

# Access specific model in console
docker compose exec web bin/rails console
# Then: Streamer.all, Annotation.first, etc.
```

## Remember

✅ **DO**: Always prefix commands with `docker compose exec web`

❌ **DON'T**: Ever run Ruby, Rails, or Bundle commands directly on your host machine

When in doubt, put `docker compose exec web` in front of any command!