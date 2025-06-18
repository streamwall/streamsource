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

# Watch mode (for development)
docker compose exec web yarn build --watch
docker compose exec web yarn build:css --watch
```

### Adding New Gems

```bash
# 1. Edit Gemfile
# 2. Rebuild the image
docker compose build web
# 3. Restart services
docker compose restart web
```

### Debugging

```bash
# View Rails routes
docker compose exec web bin/rails routes

# View Rails routes for specific controller
docker compose exec web bin/rails routes -c streams

# Interactive debugging (after adding binding.pry)
docker attach streamsource_web_1
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

### Default Admin Login
- Email: `admin@example.com`
- Password: `password123`

## Remember

✅ **DO**: Always prefix commands with `docker compose exec web`

❌ **DON'T**: Ever run Ruby, Rails, or Bundle commands directly on your host machine

When in doubt, put `docker compose exec web` in front of any command!