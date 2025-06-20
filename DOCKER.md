# Docker Configuration Documentation

## Overview

StreamSource is fully containerized using Docker and Docker Compose, providing a consistent development and production environment across all platforms.

## Files Overview

### `Dockerfile`
Production-ready multi-stage build that:
- Uses Ruby 3.3.6 slim base image
- Multi-stage build with separate test stage
- Installs all dependencies including Node.js 20 and Yarn
- Builds JavaScript and CSS assets
- Runs as non-root user for security
- Includes health check configuration
- Optimized layer caching

### `docker compose.yml`
Development environment configuration with:
- PostgreSQL 15 database
- Redis 7 for caching and sessions (with separate test database)
- Rails web application with automatic database preparation
- JavaScript and CSS build watchers (using profiles)
- Test service for isolated test runs
- Health checks for all services
- Volume mounts for development
- Proper service dependencies

### `bin/docker-entrypoint`
Entrypoint script that:
- Prepares the database on startup
- Handles Rails-specific commands
- Ensures proper bundler execution

## Quick Start

### Development Environment

1. **Start all services**
```bash
docker compose up -d
```

2. **View logs**
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f web
```

3. **Stop services**
```bash
docker compose down
```

4. **Reset everything**
```bash
docker compose down -v  # Also removes volumes
docker compose up -d --build  # Rebuild and start
```

## Service Details

### PostgreSQL Database
- **Image**: postgres:15-alpine
- **Port**: 5432
- **Credentials**:
  - Username: `streamsource`
  - Password: `streamsource_password`
  - Database: `streamsource_development`
- **Health Check**: Uses `pg_isready`
- **Data Persistence**: `postgres_data` volume

### Redis
- **Image**: redis:7-alpine
- **Port**: 6379
- **Health Check**: Uses `redis-cli ping`
- **No authentication** (development only)

### Rails Application
- **Build**: From Dockerfile in project root
- **Port**: 3000
- **Environment**:
  - `RAILS_ENV=development`
  - `DATABASE_URL` configured for PostgreSQL
  - `REDIS_URL` configured for Redis
  - `WEB_CONCURRENCY=0` for Puma in development
- **Volumes**:
  - `.:/rails:cached` - Source code (cached for performance)
- **Dependencies**: Waits for DB and Redis health
- **Automatic database setup**: Runs migrations on startup

### JavaScript/CSS Watchers (Optional)
- **js service**: Watches and rebuilds JavaScript
- **css service**: Watches and rebuilds CSS
- **Profile**: `donotstart` (manual start)
- **Usage**: `docker compose --profile donotstart up js css`

## Test Environment

### Running Tests
```bash
# Use the test-specific service
docker compose run --rm test

# Or run tests in the web container
docker compose exec web bin/test

# Run specific test file
docker compose exec web bin/test spec/models/stream_spec.rb

# Run with coverage report
docker compose exec web bin/test
# Coverage report will be in coverage/index.html
```

## Common Docker Commands

### Container Management

```bash
# List running containers
docker compose ps

# Execute commands in container
docker compose exec web bash
docker compose exec web bundle exec rails console
docker compose exec web bundle exec rails db:migrate

# Run one-off commands
docker compose run --rm web bundle exec rspec
docker compose run --rm web bundle exec rubocop

# View container resource usage
docker stats
```

### Database Operations

```bash
# Create database
docker compose exec web bundle exec rails db:create

# Run migrations
docker compose exec web bundle exec rails db:migrate

# Seed database
docker compose exec web bundle exec rails db:seed

# Reset database
docker compose exec web bundle exec rails db:reset

# Access PostgreSQL console
docker compose exec db psql -U streamsource streamsource_development
```

### Asset Management

```bash
# Build JavaScript
docker compose exec web yarn build

# Build CSS
docker compose exec web yarn build:css

# Watch mode (using separate services)
docker compose --profile donotstart up js
docker compose --profile donotstart up css

# Install new JavaScript packages
docker compose exec web yarn add <package-name>

# Install new gems
docker compose exec web bundle add <gem-name>
docker compose exec web bundle install
```

## Troubleshooting

### Container Won't Start

1. **Check logs**
```bash
docker compose logs web
```

2. **Common issues**:
   - Port already in use: `lsof -i :3000` and kill the process
   - Database not ready: Wait or check DB logs
   - Bundle issues: Rebuild with `docker compose build web`

### Database Connection Issues

1. **Verify database is running**
```bash
docker compose ps db
docker compose logs db
```

2. **Test connection**
```bash
docker compose exec db pg_isready -U streamsource
```

3. **Reset database**
```bash
docker compose down -v
docker compose up -d
docker compose exec web bundle exec rails db:setup
```

### Gem/Bundle Issues

1. **Gems not found**
```bash
# Rebuild without cache
docker compose build --no-cache web

# Or remove bundle volume and rebuild
docker compose down -v
docker compose up -d --build
```

2. **Bundle config conflicts**
```bash
# Remove local bundle config
rm -rf .bundle
docker compose build web
```

### Asset Compilation Issues

1. **JavaScript/CSS not updating**
```bash
# Rebuild assets
docker compose exec web yarn build
docker compose exec web yarn build:css

# Check asset paths
docker compose exec web ls -la public/assets/
```

2. **Node modules issues**
```bash
# Reinstall dependencies
docker compose exec web rm -rf node_modules
docker compose exec web yarn install
```

## Production Deployment

### Building Production Image

```bash
# Build production image
docker build -t streamsource:latest .

# Tag for registry
docker tag streamsource:latest your-registry.com/streamsource:latest

# Push to registry
docker push your-registry.com/streamsource:latest
```

### Running in Production

```bash
docker run -d \
  --name streamsource \
  -p 3000:3000 \
  -e RAILS_ENV=production \
  -e DATABASE_URL="postgres://user:pass@host:5432/streamsource_production" \
  -e REDIS_URL="redis://redis-host:6379/0" \
  -e SECRET_KEY_BASE="your-secret-key" \
  -e RAILS_LOG_TO_STDOUT=true \
  streamsource:latest
```

### Docker Compose Production

Create `docker compose.production.yml`:

```yaml
version: '3.8'

services:
  web:
    image: streamsource:latest
    ports:
      - "3000:3000"
    environment:
      RAILS_ENV: production
      DATABASE_URL: ${DATABASE_URL}
      REDIS_URL: ${REDIS_URL}
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

Run with:
```bash
docker compose -f docker compose.production.yml up -d
```

## Best Practices

### Development

1. **Use cached volumes** for better performance on macOS
2. **Don't store secrets** in docker compose.yml
3. **Use .dockerignore** to exclude unnecessary files
4. **Regularly update base images** for security

### Production

1. **Use specific image tags** (not `latest` in production)
2. **Run as non-root user** (already configured)
3. **Set resource limits** in production
4. **Use health checks** for orchestration
5. **Log to stdout** for container platforms
6. **Use multi-stage builds** to reduce image size

### Security

1. **Don't include development gems** in production
2. **Scan images for vulnerabilities**
```bash
docker scan streamsource:latest
```

3. **Use secrets management** for sensitive data
4. **Keep base images updated**
5. **Use read-only containers** where possible

## Docker Optimization

### Image Size Reduction

Current Dockerfile uses multi-stage build to:
- Separate build dependencies from runtime
- Exclude development/test gems in production
- Remove build artifacts and caches
- Use alpine-based images where possible

### Build Performance

1. **Leverage build cache**
   - Order Dockerfile commands from least to most frequently changing
   - Copy dependency files before source code

2. **Use .dockerignore**
   - Excludes git, logs, tmp files
   - Reduces build context size

3. **Parallel builds**
```bash
docker compose build --parallel
```

### Runtime Performance

1. **Use production mode**
   - Enables optimizations
   - Disables development features

2. **Precompile assets**
   - Done during build
   - Serves static files efficiently

3. **Connection pooling**
   - Configure database pool size
   - Use persistent Redis connections

## Monitoring

### Container Health

```bash
# Check health status
docker compose ps

# View health check logs
docker inspect streamsource-web-1 | jq '.[0].State.Health'

# Monitor resource usage
docker stats --no-stream
```

### Application Metrics

- Health endpoint: `http://localhost:3000/health`
- Readiness endpoint: `http://localhost:3000/health/ready`
- Liveness endpoint: `http://localhost:3000/health/live`
- Prometheus metrics: `http://localhost:3000/metrics`

### WebSocket Support

The application includes ActionCable for real-time features:
- Endpoint: `ws://localhost:3000/cable`
- Channels: StreamChannel, AnnotationChannel, AdminChannel

### Logging

```bash
# View logs with timestamps
docker compose logs -f --timestamps web

# Save logs to file
docker compose logs web > web.log

# Filter logs
docker compose logs web | grep ERROR
```

## Kubernetes Migration

The application is Kubernetes-ready with:

1. **Health checks** for liveness and readiness probes
2. **12-factor app** principles
3. **Stateless design** (state in PostgreSQL/Redis)
4. **Environment-based configuration**
5. **Horizontal scaling support**

Example Kubernetes deployment available in `/k8s` directory (if needed).

## Advanced Features

### Multi-Stage Build

The Dockerfile uses a multi-stage build:
1. **Base stage**: Common dependencies
2. **Build stage**: Compilation and asset building
3. **Development stage**: Full development tools
4. **Test stage**: Isolated test environment
5. **Production stage**: Minimal runtime

### Service Profiles

Docker Compose uses profiles to manage optional services:
- Default profile: web, db, redis
- `donotstart` profile: js, css (build watchers)
- Test profile: Separate test runner

### Database Initialization

The entrypoint script automatically:
- Creates the database if it doesn't exist
- Runs pending migrations
- Seeds the database in development
- Ensures proper state before starting Rails