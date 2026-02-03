# 🚀 Getting Started with StreamSource

This guide will help you set up and run StreamSource locally for development and testing.

## 📋 Prerequisites

- **Docker Desktop** - [Download here](https://www.docker.com/products/docker-desktop/)
- **Git** - For cloning the repository
- **Modern terminal** - Terminal.app, iTerm2, or similar

## 🚀 Quick Start (Recommended)

### 1. Initial Setup

```bash
# Navigate to the project directory
cd ~/dev/streamsource

# One-command setup (handles everything automatically)
make setup
```

This automated setup will:
- ✅ Create `.env` file from template
- ✅ Install Ruby gems and JavaScript dependencies
- ✅ Start PostgreSQL database
- ✅ Run database migrations
- ✅ Seed the database with sample data

### 2. Start Development Environment

```bash
# Start all services in development mode
make dev
```

This starts:
- **Rails API & Admin Interface** on http://localhost:3000
- **PostgreSQL database** container
- **Redis cache/sessions** container
- **Asset watchers** for live code reloading

## 📱 Access Points

Once running, you can access:

| Service | URL | Description |
|---------|-----|-------------|
| 🏠 **Main Application** | http://localhost:3000 | Root application |
| 👨‍💼 **Admin Interface** | http://localhost:3000/admin | Management dashboard |
| 📚 **API Documentation** | http://localhost:3000/api-docs | Interactive API docs (Swagger) |
| 🏥 **Health Check** | http://localhost:3000/health | System status endpoint |
| 🎛️ **Feature Flags** | http://localhost:3000/admin/flipper | Feature toggle management |

## 🔐 Default Admin Access

The seeded database includes an admin user:
- **Email**: `admin@example.com`
- **Password**: `Password123!`

> **Note**: Check `db/seeds.rb` for exact credentials if these don't work.

## 🔧 Alternative Startup Methods

### Background Mode
```bash
make up          # Starts services in background
make logs        # View logs in follow mode
make status      # Check container status
make down        # Stop all services
```

### Manual Setup (if automated setup fails)
```bash
# 1. Copy environment template
cp .env.example .env

# 2. Edit configuration (optional for local testing)
nano .env

# 3. Install dependencies
make install

# 4. Start database only
docker compose up -d db

# 5. Setup database
make migrate
make seed

# 6. Start everything
make dev
```

## 🧪 Testing Your Setup

### Run the Test Suite
```bash
# Full test suite with coverage
make test

# Specific test types
make test-models      # Model tests only
make test-requests    # API/request tests only
make test-parallel    # Faster parallel execution
```

### System Health Checks
```bash
# Quick health check
make health

# Comprehensive diagnostics
make doctor

# Check configuration
make env-check
```

### API Testing
```bash
# Test health endpoint
curl http://localhost:3000/health

# Test database connectivity
curl http://localhost:3000/health/db

# Test Redis connectivity
curl http://localhost:3000/health/redis

# Test API endpoints (may require authentication)
curl http://localhost:3000/api/v1/streams
```

## 🛠️ Useful Development Commands

### Core Operations
```bash
make dev         # Start in development mode
make up          # Start in background
make down        # Stop all services
make restart     # Restart all services
make logs        # Follow application logs
make status      # Show container status
```

### Development Tools
```bash
make shell       # Open bash shell in web container
make rails       # Open Rails console (alias: make c)
make routes      # Show all Rails routes
make attach      # Attach to container for debugging
```

### Database Management
```bash
make migrate     # Run pending migrations
make rollback    # Rollback last migration
make seed        # Seed database with sample data
make reset       # Reset database (⚠️ destroys data!)
make db-shell    # Open PostgreSQL shell
make backup      # Backup database and config
```

### Code Quality
```bash
make lint        # Comprehensive code analysis
make lint-fix    # Auto-fix code style issues
make lint-ruby   # Ruby style check only
make lint-js     # JavaScript style check only
make security    # Security audit and scanning
make quality     # Full quality check (lint + test)
make pre-commit  # Pre-commit validation
```

### Dependencies & Assets
```bash
make install     # Install all dependencies
make update      # Update all dependencies
make bundle      # Install Ruby gems
make yarn        # Install JavaScript packages
make assets      # Compile assets for production
make assets-dev  # Compile assets for development
```

## 🚨 Troubleshooting

### Container Issues
```bash
# Diagnose common problems
make doctor

# Clean up and rebuild
make clean
make rebuild

# Deep clean (removes everything)
make clean-all
```

### Database Problems
```bash
# Access database directly
make db-shell

# Reset database (⚠️ destroys all data)
make reset

# Check database connection
make health
```

### Performance Issues
```bash
# Check system resources
make doctor

# View detailed logs
make logs-all

# Check container status
make ps-all
```

### Common Error Messages

| Error | Solution |
|-------|----------|
| "Docker not found" | Install Docker Desktop and ensure it's running |
| "Port 3000 already in use" | Stop other Rails apps or use `make down` |
| "Database connection failed" | Run `make doctor` and check database container |
| "Permission denied" | Check file permissions with `make security` |
| "Bundle install failed" | Try `make clean` then `make rebuild` |

## 🔄 Development Workflow

### Typical Development Session
1. **Start**: `make dev`
2. **Make code changes** (auto-reloads)
3. **Test changes**: `make test`
4. **Check quality**: `make pre-commit`
5. **Stop**: `Ctrl+C` or `make down`

### Before Committing Code
```bash
# Run comprehensive checks
make pre-commit

# This runs:
# - Full test suite
# - Code style checks (Ruby & JavaScript)
# - Security analysis
# - Dependency audit
```

### Adding New Features
```bash
# 1. Create database migration (if needed)
make exec cmd="bin/rails generate migration AddFeatureToModel"

# 2. Run migration
make migrate

# 3. Generate tests
make exec cmd="bin/rails generate rspec:model Feature"

# 4. Run tests frequently
make test-watch

# 5. Check code quality
make quality
```

## 📊 Understanding the Application

### Architecture Overview
- **Rails 8** - Modern Ruby on Rails framework
- **PostgreSQL 18** - Primary database
- **Redis 8** - Caching and session storage
- **Hotwire/Stimulus** - Real-time frontend updates
- **ActionCable** - WebSocket support for real-time features
- **Docker** - Containerized development environment

### Key Features
- **RESTful API** - Comprehensive API for streams, streamers, timestamps
- **Admin Interface** - Real-time collaborative editing
- **Feature Flags** - Flipper-based feature toggles
- **Authentication** - JWT for API, sessions for admin
- **Real-time Updates** - ActionCable WebSocket support
- **Rate Limiting** - Rack::Attack protection

### Data Models
- **User** - Authentication and authorization
- **Streamer** - Content creators
- **StreamerAccount** - Platform-specific accounts
- **Stream** - Individual streaming sessions
- **Timestamp** - Event annotations/incidents

## 🎯 Quick Shortcuts

For faster development, use these shortcut commands:

```bash
make d    # dev
make u    # up
make l    # logs
make r    # restart
make s    # status
make t    # test
make c    # rails (console)
```

## 📚 Additional Resources

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Production deployment guide
- **[API Documentation](http://localhost:3000/api-docs)** - Interactive API docs (when running)
- **[LINTING.md](docs/LINTING.md)** - Code quality and linting guide
- **Vendor Documentation** - See `vendor/docs/` for framework references

## 🆘 Getting Help

If you encounter issues:

1. **Run diagnostics**: `make doctor`
2. **Check logs**: `make logs`
3. **Review health**: `make health`
4. **Clean and rebuild**: `make clean && make rebuild`
5. **Check documentation** in the `docs/` directory

## 🎉 You're Ready!

Once you have StreamSource running locally:

- ✅ **Admin Interface**: http://localhost:3000/admin
- ✅ **API Documentation**: http://localhost:3000/api-docs
- ✅ **Health Monitoring**: http://localhost:3000/health
- ✅ **Real-time Features**: WebSocket support enabled
- ✅ **Development Tools**: Rails console, logs, debugging

Happy coding! 🚀

---

> **💡 Pro Tip**: Use `make help` anytime to see all available commands with descriptions.
