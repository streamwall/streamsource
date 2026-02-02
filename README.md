# StreamSource

A modern Rails 8 application for managing streamers and streaming sources with both a RESTful API and a real-time collaborative admin interface. Features JWT authentication, role-based authorization, real-time updates with Hotwire and ActionCable, and comprehensive deployment automation.

## Table of Contents

- [Features](#features)
- [Technology Stack](#technology-stack)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Quick Start with Docker](#quick-start-with-docker)
  - [Environment Configuration](#environment-configuration)
- [Architecture](#architecture)
- [Admin Interface](#admin-interface)
- [API Documentation](#api-documentation)
- [Testing](#testing)
- [Deployment](#deployment)
- [Development](#development)
- [Contributing](#contributing)

## Features

### Core Features
- **Dual Authentication**: JWT for API, session-based for admin interface
- **Real-time Collaboration**: Cell-level locking for concurrent editing with presence tracking
- **Role-Based Access Control**: Three-tier role system (default, editor, admin)
- **Streamer Management**: Track content creators across multiple platforms
- **Stream Management**: Full CRUD with smart continuation logic (30-minute window)
- **Timestamp System**: Event annotations across multiple streams
- **Platform Support**: TikTok, Facebook, Twitch, YouTube, Instagram, Other
- **Advanced Filtering**: By status, user, platform, pin state, and archival status
- **WebSocket Support**: ActionCable for real-time updates

### Technical Features
- **Rate Limiting**: Comprehensive request throttling via Rack::Attack
- **Health Monitoring**: Kubernetes-ready health check endpoints
- **API Documentation**: Interactive OpenAPI/Swagger documentation
- **Feature Flags**: Flipper-based feature management
- **Smart Caching**: Redis-backed with 90-minute expiration
- **Automated Deployment**: GitHub Actions CI/CD pipeline
- **Cost Optimization**: Scheduled power management for 67% cost savings
- **Security Hardened**: SSL, CORS, CSP headers, fail2ban
- **100% Docker**: Fully containerized development and production

## Technology Stack

### Backend
- **Framework**: Rails 8.0.x (API + Admin)
- **Language**: Ruby 4.0.1
- **Database**: PostgreSQL 18
- **Cache/Sessions**: Redis 8
- **Web Server**: Puma with multi-worker support

### Frontend (Admin Interface)
- **JavaScript**: Hotwire (Turbo + Stimulus) with esbuild
- **CSS**: Tailwind CSS 4.x
- **Real-time**: ActionCable WebSockets
- **Build Tools**: Node.js 24, Yarn

### Authentication & Security
- **API Auth**: JWT with 24-hour expiration
- **Admin Auth**: Devise with bcrypt
- **Authorization**: Pundit policies
- **Rate Limiting**: Rack::Attack
- **CORS**: Rack::Cors

### Infrastructure
- **Containerization**: Docker & Docker Compose
- **CI/CD**: GitHub Actions (free tier)
- **Deployment**: DigitalOcean Droplet ($6/month)
- **Proxy**: Nginx with SSL/TLS
- **Monitoring**: Health checks, optional Sentry

### Development & Testing
- **Testing**: RSpec, FactoryBot, SimpleCov (high coverage)
- **API Mocking**: WebMock, VCR
- **Code Quality**: RuboCop, Brakeman
- **Debugging**: Better Errors, Bullet (N+1)

## Getting Started

### Prerequisites

- **Docker and Docker Compose** (required)
- **Git** for version control
- **A text editor** (VS Code, etc.)

> **Important**: This project runs exclusively in Docker containers. Never use system Ruby or Bundler.

### Quick Start with Docker

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/streamsource.git
cd streamsource
```

2. **Copy environment file**
```bash
cp .env.example .env
```

3. **Start the application**
```bash
docker compose up -d
```

4. **View logs** (optional)
```bash
docker compose logs -f web
```

The application will automatically:
- Create and migrate the database
- Seed sample data including an admin user
- Build JavaScript and CSS assets
- Start the Rails server

5. **Access the application**
- API: `http://localhost:3000`
- Admin Interface: `http://localhost:3000/admin`
- API Documentation: `http://localhost:3000/api-docs`
- Feature Flags: `http://localhost:3000/admin/flipper`

### Default Credentials

**Admin User** (development only):
- Email: `admin@example.com`
- Password: `Password123!`

### Environment Configuration

See [Environment Variables Documentation](docs/ENVIRONMENT_VARIABLES.md) for comprehensive configuration options.

Key variables:
- `SECRET_KEY_BASE` - Required for production
- `DATABASE_URL` - PostgreSQL connection
- `REDIS_URL` - Redis connection
- `APPLICATION_HOST` - Your domain name

## Architecture

### Data Models

1. **User** - Authentication with roles (default, editor, admin)
2. **Streamer** - Content creators with normalized names
3. **StreamerAccount** - Platform-specific accounts with auto-generated URLs
4. **Stream** - Streaming sessions with smart continuation logic
5. **Timestamp** - Event annotations linked to streams

### Key Design Decisions

- **Removed Models**: Notes and StreamUrl were removed for simplicity
- **Smart Continuation**: Streams within 30 minutes are considered continuous
- **Real-time Collaboration**: Redis-backed cell locking prevents conflicts
- **Feature Flags**: Gradual rollout and A/B testing support
- **Zero-downtime Deployment**: Symlink-based with automatic rollback

## Admin Interface

### Real-time Collaborative Editing

The admin interface supports multiple users editing simultaneously:

- **Cell-level locking**: Click to edit, automatic lock acquisition
- **Presence tracking**: See who's editing what in real-time
- **Color coding**: Each user gets a unique color
- **Auto-unlock**: 5-second timeout or disconnect releases locks
- **Conflict prevention**: Can't edit locked cells

### Key Pages

- `/admin/streams` - Stream management with filters and search
- `/admin/streamers` - Streamer and account management
- `/admin/timestamps` - Event tracking across streams
- `/admin/users` - User and role management
- `/admin/flipper` - Toggle features via Flipper UI

### Keyboard Shortcuts

- `Cmd/Ctrl + K` - Quick search
- `Escape` - Close modals
- `Tab` - Navigate form fields

## API Documentation

### Interactive Documentation

Access Swagger UI at `http://localhost:3000/api-docs` for interactive API exploration.

### Authentication Flow

1. **Get a token**:
```bash
curl -X POST http://localhost:3000/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "Password123!"}'
```

2. **Use the token**:
```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:3000/api/v1/streams
```

### Core Endpoints

#### Streams
- `GET /api/v1/streams` - List with pagination and filters
- `POST /api/v1/streams` - Create new stream
- `PATCH /api/v1/streams/:id` - Update stream
- `PUT /api/v1/streams/:id/pin` - Pin important streams
- `POST /api/v1/streams/:id/archive` - Archive old streams

#### Streamers
- Full CRUD operations
- Automatic platform URL generation
- Account management

#### Timestamps
- Link events to multiple streams
- Priority levels
- Time-based queries

### WebSocket Support

Connect to `/cable` for real-time updates:
- Stream status changes
- Collaborative editing events
- Live notifications (when enabled)

## Testing

### Running Tests

```bash
# Run all tests with coverage
docker compose exec web bin/test

# Run specific test file
docker compose exec web bin/test spec/models/stream_spec.rb

# Run with specific pattern
docker compose exec web bin/test spec/controllers/api
```

### Test Coverage

- **Models**: 100% coverage with edge cases
- **Controllers**: All endpoints tested
- **Policies**: Authorization rules verified
- **Integration**: Full request/response cycles
- **WebSockets**: ActionCable channels tested

### Continuous Integration

GitHub Actions runs on every push:
1. Full test suite with PostgreSQL and Redis
2. Security scanning with Brakeman
3. Dependency audit
4. Automatic deployment on main branch

## Deployment

### Production Deployment

See [DigitalOcean Deployment Guide](DIGITALOCEAN_DEPLOYMENT_GUIDE.md) for detailed instructions.

**Quick Deploy** (after initial setup):
```bash
make deploy HOST=your-droplet-ip
```

### Cost-Optimized Infrastructure

- **Droplet**: $6/month (Basic plan)
- **Automated Shutdown**: 16 hours/day = 67% savings
- **Total Cost**: ~$6/month vs $27/month for always-on

### GitHub Actions Deployment

1. **Push to main branch** → Tests run → Auto-deploy
2. **Manual deployment**: Actions tab → Run workflow
3. **Scheduled power**: Auto on/off via cron

Required secrets:
- `DROPLET_HOST` - Server IP/domain
- `DEPLOY_SSH_KEY` - Deployment key
- `DO_API_TOKEN` - For power management
- `DROPLET_ID` - Droplet identifier

## Development

### Common Tasks

```bash
# Rails console
docker compose exec web bin/rails console

# Database tasks
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails db:seed

# Asset compilation
docker compose exec web yarn build
docker compose exec web yarn build:css

# Linting
docker compose exec web bundle exec rubocop -A

# View logs
docker compose logs -f web
```

### Adding Features

1. **Create feature flag** in Flipper UI
2. **Write tests** first (TDD)
3. **Implement feature** behind flag
4. **Test locally** with flag enabled
5. **Deploy** and test in production
6. **Gradually enable** for users

### Code Style Guidelines

- Follow Rails conventions
- Thin controllers, fat models
- Service objects for complex logic
- Policy objects for authorization
- Comprehensive tests
- Clear documentation

## Monitoring

### Health Checks

- `/health` - Basic health check
- `/health/live` - Kubernetes liveness
- `/health/ready` - Readiness probe
- `/metrics` - Prometheus metrics (when enabled)

### Logging

- Structured JSON logs with Lograge
- Request IDs for tracing
- Performance metrics included
- Error tracking ready (Sentry)

### Performance

- Average response time: <100ms
- WebSocket latency: <50ms
- Database queries optimized
- N+1 queries prevented

## Security

### Built-in Protections

- **SSL/TLS** enforced in production
- **CORS** configured for API access
- **CSP headers** prevent XSS
- **Rate limiting** prevents abuse
- **SQL injection** prevented by ActiveRecord
- **CSRF protection** for web interface
- **Secure headers** via middleware

### Best Practices

- Regular dependency updates via Dependabot
- Security scanning in CI pipeline
- Secrets rotation recommended
- Audit logs for sensitive actions
- Encrypted credentials in Rails

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Write comprehensive tests
4. Ensure all tests pass
5. Follow code style guidelines
6. Update relevant documentation
7. Commit with clear messages
8. Push to branch (`git push origin feature/amazing-feature`)
9. Open Pull Request with description

### Development Setup

```bash
# Fork and clone
git clone https://github.com/yourusername/streamsource.git
cd streamsource

# Start development environment
docker compose up -d

# Run tests
docker compose exec web bin/test

# Make changes and test
```

## Troubleshooting

### Common Issues

**Container won't start**
- Check Docker is running
- Ensure ports 3000, 5432, 6379 are free
- Run `docker compose logs web` for errors

**Database errors**
- Run `docker compose exec web bin/rails db:reset`
- Check DATABASE_URL in .env

**Asset compilation fails**
- Run `docker compose exec web yarn install`
- Check Node/Yarn versions

**Tests failing**
- Ensure test database exists
- Run `docker compose exec web bin/rails db:test:prepare`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: Check `/docs` folder
- **Issues**: GitHub Issues for bug reports
- **Discussions**: GitHub Discussions for questions
- **Security**: Report vulnerabilities privately

---

Built with ❤️ using Rails 8, Hotwire, and modern web standards.
