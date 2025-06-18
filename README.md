# StreamSource

A modern Rails 8 application for managing streaming sources with both a RESTful API and an admin interface. Features JWT authentication, role-based authorization, real-time updates with Hotwire, and comprehensive rate limiting.

## Table of Contents

- [Features](#features)
- [Technology Stack](#technology-stack)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Quick Start with Docker](#quick-start-with-docker)
  - [Local Installation](#local-installation)
- [Admin Interface](#admin-interface)
- [API Documentation](#api-documentation)
- [Configuration](#configuration)
- [Testing](#testing)
- [Development](#development)
- [Deployment](#deployment)
- [Contributing](#contributing)

## Features

### Core Features
- **JWT Authentication**: Secure token-based authentication for API access
- **Session Authentication**: Cookie-based authentication for admin interface
- **Role-Based Access Control**: Three-tier role system (default, editor, admin)
- **Stream Management**: Full CRUD operations for streaming sources
- **Pin/Unpin Functionality**: Highlight important streams
- **Advanced Filtering**: Filter streams by status, user, and pin state
- **Real-time Updates**: Hotwire-powered admin interface with Turbo and Stimulus

### Technical Features
- **Rate Limiting**: Comprehensive request throttling to prevent abuse
- **Health Checks**: Kubernetes-ready health and readiness endpoints
- **API Documentation**: Interactive OpenAPI/Swagger documentation
- **Feature Flags**: Flipper-based feature management system
- **Pagination**: Efficient data loading with Pagy
- **Docker Support**: Fully containerized application
- **Test Coverage**: Comprehensive test suite with high coverage

## Technology Stack

### Backend
- **Framework**: Rails 8.0.2 (API + Admin interface)
- **Language**: Ruby 3.3.0
- **Database**: PostgreSQL 15
- **Cache/Sessions**: Redis 7
- **Background Jobs**: Sidekiq (ready for expansion)

### Frontend (Admin Interface)
- **JavaScript**: Hotwire (Turbo + Stimulus)
- **CSS**: Tailwind CSS 3.4
- **Build Tools**: ESBuild + Yarn

### Authentication & Security
- **API Auth**: JWT (JSON Web Tokens) via devise-jwt
- **Admin Auth**: Session-based authentication
- **Authorization**: Pundit policies
- **Rate Limiting**: Rack::Attack

### Development & Testing
- **Testing**: RSpec, FactoryBot, SimpleCov
- **API Documentation**: Rswag (OpenAPI/Swagger)
- **Code Quality**: RuboCop with Rails Omakase
- **Containerization**: Docker & Docker Compose

## Getting Started

### Prerequisites

- **Docker and Docker Compose** (required)

> **Important**: This project is designed to run exclusively in Docker containers. Do not attempt to use system Ruby or Bundler - all development tasks should be performed within the Docker environment.

### Quick Start with Docker

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/streamsource.git
cd streamsource
```

2. **Start the application**
```bash
docker compose up -d
```

3. **View logs** (optional)
```bash
docker compose logs -f web
```

The application will automatically:
- Create and migrate the database
- Seed sample data including an admin user
- Build JavaScript and CSS assets
- Start the Rails server

4. **Access the application**
- API: `http://localhost:3000`
- Admin Interface: `http://localhost:3000/admin`
- API Documentation: `http://localhost:3000/api-docs`

### Default Admin Credentials

In development mode, a default admin user is created:
- **Email**: `admin@example.com`
- **Password**: `password123`

## Admin Interface

The application includes a full-featured admin interface built with Hotwire:

### Features
- **Stream Management**: Create, edit, delete, and pin/unpin streams
- **Real-time Search**: Filter streams as you type with debounced search
- **Modal Forms**: Seamless editing with Turbo Frames
- **Responsive Design**: Mobile-friendly interface with Tailwind CSS
- **User Management**: Manage users and their roles
- **Feature Flags**: Toggle features on/off via Flipper UI

### Accessing the Admin Interface
1. Navigate to `http://localhost:3000/admin`
2. Login with admin credentials
3. Use the sidebar navigation to access different sections

### Admin Routes
- `/admin` - Dashboard (redirects to streams)
- `/admin/streams` - Manage streams
- `/admin/users` - Manage users
- `/admin/feature_flags` - Feature flag management

## API Documentation

### Interactive Documentation
Access the Swagger UI at `http://localhost:3000/api-docs` for interactive API documentation.

### Authentication

#### Getting a Token
```bash
curl -X POST http://localhost:3000/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

#### Using the Token
Include the JWT token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

### Main Endpoints

#### Authentication
- `POST /api/v1/users/signup` - Create new user account
- `POST /api/v1/users/login` - Authenticate and receive JWT token

#### Streams
- `GET /api/v1/streams` - List all streams (paginated)
- `GET /api/v1/streams/:id` - Get specific stream
- `POST /api/v1/streams` - Create new stream
- `PATCH /api/v1/streams/:id` - Update stream
- `DELETE /api/v1/streams/:id` - Delete stream
- `PUT /api/v1/streams/:id/pin` - Pin stream
- `DELETE /api/v1/streams/:id/pin` - Unpin stream

#### Additional Features (with feature flags)
- `GET /api/v1/streams/:id/analytics` - Stream analytics
- `GET /api/v1/streams/export` - Export streams
- `POST /api/v1/streams/bulk_import` - Bulk import streams

#### Health & Monitoring
- `GET /health` - Basic health check
- `GET /health/live` - Liveness probe
- `GET /health/ready` - Readiness probe
- `GET /metrics` - Prometheus metrics

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and update:

```bash
# Database
DATABASE_URL=postgres://streamsource:password@localhost:5432/streamsource_development

# Redis
REDIS_URL=redis://localhost:6379/0

# Rails
RAILS_ENV=development
SECRET_KEY_BASE=your-secret-key-base

# Feature Flags (optional)
FLIPPER_UI_USERNAME=admin
FLIPPER_UI_PASSWORD=secure_password

# Monitoring (optional)
SKYLIGHT_AUTHENTICATION=your-skylight-token
```

### Application Constants

Configuration is centralized in `config/application_constants.rb`:
- JWT settings (algorithm, expiration time)
- Pagination defaults
- Password requirements
- Rate limiting thresholds
- Feature flag names

## Testing

### Running Tests

All tests must be run within the Docker container:

```bash
# Run all tests
docker compose exec web bin/test

# Run with coverage
docker compose exec web bin/test

# Run specific tests
docker compose exec web bin/test spec/controllers/api/v1/streams_controller_spec.rb

# Run tests in a new container (if services aren't running)
docker compose run --rm web bin/test
```

> **Note**: The `bin/test` script automatically sets `RAILS_ENV=test` and prepares the test database.

### Test Coverage

The test suite covers:
- Models with validations and associations
- Controllers with all endpoints
- Policies for authorization rules
- Serializers for JSON output
- Request specs for integration testing
- Middleware configuration
- Feature flag behavior

## Development

All development tasks must be performed within the Docker container. Never use system Ruby or Bundler.

### Common Docker Commands

```bash
# Execute commands in the running container
docker compose exec web [command]

# Run commands in a new container
docker compose run --rm web [command]

# View logs
docker compose logs -f web

# Restart services
docker compose restart web
```

### Code Style

```bash
# Run linter
docker compose exec web bundle exec rubocop

# Auto-fix issues
docker compose exec web bundle exec rubocop -A
```

### Asset Development

```bash
# Rebuild JavaScript
docker compose exec web yarn build

# Rebuild CSS
docker compose exec web yarn build:css

# Watch mode (run in separate terminals)
docker compose exec web yarn build --watch
docker compose exec web yarn build:css --watch
```

### Database Tasks

```bash
# Run migrations
docker compose exec web bin/rails db:migrate

# Rollback migration
docker compose exec web bin/rails db:rollback

# Reset database (drop, create, migrate, seed)
docker compose exec web bin/rails db:reset

# Access database console
docker compose exec db psql -U streamsource
```

### Debugging

```bash
# Access Rails console
docker compose exec web bin/rails console

# View application logs
docker compose logs -f web

# Check routes
docker compose exec web bin/rails routes

# Run any Rails command
docker compose exec web bin/rails [command]
```

### Installing New Gems

When adding new gems to the Gemfile:

```bash
# 1. Edit Gemfile
# 2. Rebuild the Docker image
docker compose build web

# 3. Restart the services
docker compose up -d
```

## Deployment

### Production Docker Build

```bash
# Build production image
docker build -t streamsource:latest .

# Run with environment variables
docker run -d \
  -p 3000:3000 \
  -e DATABASE_URL=postgres://... \
  -e REDIS_URL=redis://... \
  -e SECRET_KEY_BASE=... \
  -e RAILS_ENV=production \
  streamsource:latest
```

### Kubernetes Deployment

The application includes health checks for Kubernetes:
- Liveness probe: `/health/live`
- Readiness probe: `/health/ready`

### Production Checklist

1. Set strong `SECRET_KEY_BASE`
2. Configure production database
3. Set up Redis for caching and sessions
4. Configure email delivery (if needed)
5. Set up monitoring (New Relic, AppSignal, etc.)
6. Configure log aggregation
7. Set up SSL/TLS termination
8. Configure CORS for your domains
9. Review and adjust rate limiting
10. Set production feature flags

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Guidelines

- Follow TDD/BDD practices
- Keep controllers thin, models fat
- Use service objects for complex business logic
- Document public APIs and complex methods
- Update relevant documentation
- Ensure high test coverage
- Follow Ruby style guide

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with Rails 8 and modern Ruby practices
- Admin interface powered by Hotwire
- Styled with Tailwind CSS
- Comprehensive test suite ensures reliability
- Security-first approach throughout