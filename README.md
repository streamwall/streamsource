# StreamSource API

A modern, secure Rails 8 API for managing streaming sources with JWT authentication, role-based authorization, and comprehensive rate limiting.

## Table of Contents

- [Features](#features)
- [Technology Stack](#technology-stack)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Docker Setup](#docker-setup)
- [Configuration](#configuration)
- [API Documentation](#api-documentation)
- [Testing](#testing)
- [Architecture](#architecture)
- [Security](#security)
- [Development](#development)
- [Deployment](#deployment)
- [Contributing](#contributing)

## Features

- **JWT Authentication**: Secure token-based authentication system
- **Role-Based Access Control**: Three-tier role system (default, editor, admin)
- **Stream Management**: Full CRUD operations for streaming sources
- **Pin/Unpin Functionality**: Highlight important streams
- **Advanced Filtering**: Filter streams by status, user, and pin state
- **Pagination**: Efficient data loading with configurable page sizes
- **Rate Limiting**: Comprehensive request throttling to prevent abuse
- **Health Checks**: Kubernetes-ready health and readiness endpoints
- **API Documentation**: OpenAPI/Swagger documentation
- **Docker Support**: Fully containerized application
- **Test Coverage**: Comprehensive test suite with 100% coverage goal
- **Feature Flags**: Flipper-based feature management system

## Technology Stack

- **Framework**: Rails 8.0.2 (API mode)
- **Language**: Ruby 3.3.6
- **Database**: PostgreSQL 15
- **Cache/Sessions**: Redis 7
- **Authentication**: JWT (JSON Web Tokens)
- **Authorization**: Pundit
- **Rate Limiting**: Rack::Attack
- **Testing**: RSpec, FactoryBot, SimpleCov
- **API Documentation**: Rswag (OpenAPI/Swagger)
- **Serialization**: ActiveModel::Serializers
- **Containerization**: Docker & Docker Compose
- **Feature Flags**: Flipper with ActiveRecord adapter

## Getting Started

### Prerequisites

- Docker and Docker Compose (recommended)
- OR Ruby 3.3.6, PostgreSQL 15, and Redis 7

### Installation

#### Using Docker (Recommended)

1. Clone the repository:
```bash
git clone https://github.com/yourusername/streamsource.git
cd streamsource
```

2. Start the application:
```bash
docker-compose up -d
```

3. Set up the database:
```bash
docker-compose exec web bin/rails db:create db:migrate db:seed
```

4. The API will be available at `http://localhost:3000`

#### Local Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/streamsource.git
cd streamsource
```

2. Install dependencies:
```bash
bundle install
```

3. Set up the database:
```bash
bin/rails db:create db:migrate db:seed
```

4. Start Redis:
```bash
redis-server
```

5. Start the Rails server:
```bash
bin/rails server
```

### Docker Setup

The application includes Docker configuration for both development and production environments:

- `Dockerfile`: Production-ready multi-stage build
- `docker-compose.yml`: Development environment with PostgreSQL and Redis
- `Dockerfile.test`: Test environment configuration

## Configuration

### Environment Variables

Create a `.env` file based on `.env.example`:

```bash
# Database
DATABASE_URL=postgres://user:password@localhost:5432/streamsource_development

# Redis
REDIS_URL=redis://localhost:6379/0

# Rails
RAILS_ENV=development
SECRET_KEY_BASE=your-secret-key-base

# Application
RAILS_LOG_TO_STDOUT=true
```

### Application Constants

All magic numbers and configuration values are centralized in `config/application_constants.rb`:

- JWT configuration (algorithm, expiration)
- Pagination settings (default/max per page)
- Password requirements
- Stream validation rules
- Rate limiting thresholds
- Application metadata

## API Documentation

### Authentication

All endpoints except health checks and authentication endpoints require JWT authentication.

Include the JWT token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

### Endpoints

#### Authentication

- `POST /api/v1/users/signup` - Create new user account
- `POST /api/v1/users/login` - Authenticate and receive JWT token

#### Streams

- `GET /api/v1/streams` - List all streams (paginated)
- `GET /api/v1/streams/:id` - Get specific stream
- `POST /api/v1/streams` - Create new stream (editor/admin only)
- `PATCH /api/v1/streams/:id` - Update stream (owner/admin only)
- `DELETE /api/v1/streams/:id` - Delete stream (owner/admin only)
- `PUT /api/v1/streams/:id/pin` - Pin stream
- `DELETE /api/v1/streams/:id/pin` - Unpin stream

#### Health Checks

- `GET /health` - Basic health check
- `GET /health/live` - Liveness probe
- `GET /health/ready` - Readiness probe (includes database check)

### Query Parameters

#### Filtering Streams

- `status` - Filter by status (active/inactive)
- `notStatus` - Exclude streams with specific status
- `user_id` - Filter by user ID
- `is_pinned` - Filter by pin state (true/false)

#### Pagination

- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 25, max: 100)

### Example Requests

#### Sign Up
```bash
curl -X POST http://localhost:3000/api/v1/users/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123",
    "role": "editor"
  }'
```

#### Login
```bash
curl -X POST http://localhost:3000/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123"
  }'
```

#### Create Stream
```bash
curl -X POST http://localhost:3000/api/v1/streams \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Stream",
    "url": "https://example.com/stream"
  }'
```

## Testing

The application includes a comprehensive test suite with the goal of 100% code coverage.

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run with coverage report
COVERAGE=true bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run tests in Docker
docker-compose -f docker-compose.test.yml run --rm test
```

### Test Coverage

Tests cover:
- Models (User, Stream)
- Controllers (all endpoints)
- Policies (authorization rules)
- Serializers (JSON output)
- Request specs (integration tests)
- Routing specs
- Middleware (Rack::Attack)

Coverage reports are generated in the `coverage/` directory.

## Architecture

### Directory Structure

```
streamsource/
├── app/
│   ├── controllers/
│   │   ├── api/v1/         # Versioned API controllers
│   │   └── concerns/       # Shared controller concerns
│   ├── models/             # ActiveRecord models
│   ├── policies/           # Pundit authorization policies
│   └── serializers/        # JSON serializers
├── config/
│   ├── initializers/       # Application initialization
│   └── application_constants.rb  # Centralized constants
├── db/
│   ├── migrate/            # Database migrations
│   └── seeds.rb            # Seed data
├── spec/                   # Test suite
└── docker/                 # Docker configurations
```

### Design Patterns

- **Service-Oriented Architecture**: Controllers are thin, business logic in models
- **Policy Objects**: Authorization logic separated into policy classes
- **Serializer Pattern**: Consistent JSON output formatting
- **Concern Separation**: Shared functionality extracted to concerns
- **Configuration Management**: All constants centralized

## Security

### Authentication

- JWT tokens with 24-hour expiration
- Secure password requirements (min 8 chars, uppercase, lowercase, number)
- Token included in Authorization header

### Authorization

- Role-based access control (RBAC)
- Three roles: default, editor, admin
- Policies define granular permissions

### Rate Limiting

- General: 100 requests/minute per IP
- Login: 5 attempts/20 minutes per IP/email
- Signup: 3 attempts/hour per IP
- Exponential backoff for repeat violators

### Best Practices

- No sensitive data in logs
- Parameterized queries prevent SQL injection
- Input validation on all endpoints
- CORS configured for API access
- Secure headers via Rails defaults

## Development

### Code Style

The project follows Ruby community standards:
- Rubocop for code linting
- 2 spaces for indentation
- Descriptive variable and method names
- Comprehensive code comments

### Database Management

```bash
# Create database
bin/rails db:create

# Run migrations
bin/rails db:migrate

# Seed sample data
bin/rails db:seed

# Reset database
bin/rails db:reset
```

### Debugging

- Use `binding.pry` for debugging
- Rails console: `bin/rails console`
- View logs: `tail -f log/development.log`

## Deployment

### Production Configuration

1. Set production environment variables
2. Precompile assets (if any): `bin/rails assets:precompile`
3. Run migrations: `bin/rails db:migrate`
4. Start server with production settings

### Docker Production Build

```bash
docker build -t streamsource:latest .
docker run -p 3000:3000 \
  -e DATABASE_URL=postgres://... \
  -e REDIS_URL=redis://... \
  -e SECRET_KEY_BASE=... \
  -e RAILS_ENV=production \
  streamsource:latest
```

### Health Monitoring

Use the health check endpoints for container orchestration:
- `/health` - Basic health
- `/health/live` - Kubernetes liveness probe
- `/health/ready` - Kubernetes readiness probe

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass and coverage remains high
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Guidelines

- Write tests first (TDD)
- Keep controllers thin
- Document complex logic
- Update API documentation
- Follow existing code style

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with Rails 8 and modern Ruby practices
- Inspired by RESTful API design principles
- Comprehensive test suite ensures reliability
- Security-first approach throughout