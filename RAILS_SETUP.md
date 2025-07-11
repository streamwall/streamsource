# Rails 8 Setup Instructions

## 🚨 IMPORTANT: Docker-Only Development 🚨

**This project runs EXCLUSIVELY in Docker containers. Do NOT use system Ruby, Bundler, or any host machine tools.**

## Ruby Version Requirement

This project uses:
- Ruby 3.3.6
- Rails 8.0.x
- PostgreSQL 17
- Redis 7
- Node.js 20

## Setup Instructions

### Required: Using Docker
```bash
# Clone the repository
git clone [repository-url]
cd streamsource

# Start all services with Docker Compose
docker compose up -d

# The application automatically:
# - Creates and migrates the database
# - Seeds sample data including admin user
# - Builds JavaScript and CSS assets
# - Starts the Rails server

# Verify everything is running
docker compose ps

# Check logs
docker compose logs -f web
```

### Accessing the Application
- **API**: http://localhost:3000
- **Admin Interface**: http://localhost:3000/admin (admin@example.com / Password123!)
- **API Documentation**: http://localhost:3000/api-docs

## DO NOT Install Ruby Locally

While it's technically possible to install Ruby locally using rbenv or rvm, **this is strongly discouraged** for this project. All development must be done through Docker to ensure consistency across environments.

## Application Structure

The StreamSource Rails 8 application includes:

### Core Models
- **User**: Authentication with bcrypt, role-based permissions (default, editor, admin)
- **Stream**: Comprehensive streaming source management with:
  - Location tracking (city, state)
  - Platform integration
  - Status management (active, inactive, live, ended)
  - Archiving capability
  - Pinning functionality
  - Timestamps (started_at, ended_at)
- **Streamer**: Content creator profiles
- **StreamerAccount**: Platform-specific accounts for streamers
- **StreamUrl**: URL management and validation
- **Annotation**: Incident/event tracking with priority and status
- **AnnotationStream**: Many-to-many relationship for annotations
- **Note**: Polymorphic notes attachable to streams or streamers

### Controllers

#### API Controllers (api/v1/)
- **UsersController**: Signup/login endpoints
- **StreamsController**: Full CRUD with filtering, pinning, archiving
- **StreamersController**: Streamer management
- **AnnotationsController**: Incident tracking
- **NotesController**: Note management
- **HealthController**: Health check endpoints

#### Admin Controllers (admin/)
- **StreamsController**: Web interface for stream management
- **StreamersController**: Web interface for streamer management
- **AnnotationsController**: Web interface for annotation management
- **UsersController**: User administration
- **NotesController**: Note viewing
- **SessionsController**: Admin authentication

### Authentication & Authorization
- **API**: JWT-based authentication with 24-hour tokens
- **Admin**: Session-based authentication
- **Authorization**: Pundit policies for role-based access control
- **Roles**: default (view only), editor (CRUD own), admin (full access)

### Real-time Features
- **ActionCable**: WebSocket support for real-time updates
- **Channels**: StreamChannel, AnnotationChannel, AdminChannel
- **Hotwire**: Turbo + Stimulus for dynamic UI

### Security & Performance
- **Rate Limiting**: Rack::Attack configuration
- **CORS**: Rack::Cors for API access control
- **Caching**: Redis integration
- **Pagination**: Pagy for all pagination needs
- **N+1 Detection**: Bullet in development
- **Logging**: Lograge for structured logs

### Testing
- **RSpec 6.1**: Comprehensive test suite
- **FactoryBot**: Test data generation
- **SimpleCov**: Code coverage reporting
- **Database Cleaner**: Proper test isolation
- **WebMock & VCR**: External API testing

### Asset Pipeline
- **JavaScript**: ESBuild bundler
- **CSS**: Tailwind CSS via cssbundling-rails
- **Watch Mode**: Separate Docker services for development

## Key API Endpoints

See full documentation at http://localhost:3000/api-docs

### Authentication
- `POST /api/v1/users/signup` - Create new account
- `POST /api/v1/users/login` - Login

### Streams
- `GET /api/v1/streams` - List streams (with filtering and pagination)
- `GET /api/v1/streams/:id` - Show stream
- `POST /api/v1/streams` - Create stream
- `PATCH /api/v1/streams/:id` - Update stream
- `DELETE /api/v1/streams/:id` - Delete stream
- `PUT /api/v1/streams/:id/pin` - Pin stream
- `DELETE /api/v1/streams/:id/pin` - Unpin stream
- `POST /api/v1/streams/:id/archive` - Archive stream
- `POST /api/v1/streams/:id/unarchive` - Unarchive stream

### Streamers
- `GET /api/v1/streamers` - List streamers
- `GET /api/v1/streamers/:id` - Show streamer
- `POST /api/v1/streamers` - Create streamer
- `PATCH /api/v1/streamers/:id` - Update streamer
- `DELETE /api/v1/streamers/:id` - Delete streamer

### Annotations
- `GET /api/v1/annotations` - List annotations
- `GET /api/v1/annotations/:id` - Show annotation
- `POST /api/v1/annotations` - Create annotation
- `PATCH /api/v1/annotations/:id` - Update annotation
- `DELETE /api/v1/annotations/:id` - Delete annotation

### Health & Monitoring
- `GET /health` - Basic health check
- `GET /health/live` - Liveness probe
- `GET /health/ready` - Readiness probe (checks DB)
- `GET /metrics` - Prometheus metrics

### WebSocket
- `ws://localhost:3000/cable` - ActionCable endpoint

## Development Commands

All commands must be run with Docker:

```bash
# Rails console
docker compose exec web bin/rails console

# Run tests
docker compose exec web bin/test

# Run specific test
docker compose exec web bin/test spec/models/stream_spec.rb

# Generate migration
docker compose exec web bin/rails g migration AddFieldToModel

# Run migrations
docker compose exec web bin/rails db:migrate

# Check routes
docker compose exec web bin/rails routes

# Lint code
docker compose exec web bundle exec rubocop

# Build assets
docker compose exec web yarn build
docker compose exec web yarn build:css
```

## Next Steps

1. Review the API documentation at http://localhost:3000/api-docs
2. Explore the admin interface at http://localhost:3000/admin
3. Run the test suite to ensure everything is working
4. Check out the feature flags at http://localhost:3000/admin/feature_flags
5. Review CONTRIBUTING.md for development guidelines