# Rails 8 Setup Instructions

## Ruby Version Requirement

Rails 8 requires Ruby 3.2 or higher. Your system Ruby (2.6.10) is too old.

## Installation Options

### Option 1: Using rbenv (Recommended)
```bash
# Install rbenv
brew install rbenv ruby-build

# Install Ruby 3.3.0
rbenv install 3.3.0
rbenv global 3.3.0

# Add to your shell profile
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
source ~/.zshrc
```

### Option 2: Using rvm
```bash
# Install rvm
\curl -sSL https://get.rvm.io | bash -s stable

# Install Ruby 3.3.0
rvm install 3.3.0
rvm use 3.3.0 --default
```

### Option 3: Using Docker (No Ruby Installation Required)
```bash
# Start all services with Docker Compose
docker compose up

# In another terminal, run migrations
docker compose exec web rails db:create db:migrate db:seed

# Run tests
docker compose exec web rspec
```

## Rails Setup

Once Ruby 3.2+ is installed:

```bash
# Install Rails
gem install rails -v '~> 8.0.0'

# Install dependencies
bundle install

# Setup database
rails db:create db:migrate db:seed

# Start the server
rails server
```

## Application Structure Created

I've manually created a complete Rails 8 API application with:

### Models
- **User**: Authentication with Devise-JWT, role-based permissions (default, editor, admin)
- **Stream**: URL and name with status (active/inactive) and pinning functionality

### Controllers
- **ApplicationController**: Base controller with error handling
- **Api::V1::BaseController**: API base with JWT authentication
- **Api::V1::UsersController**: Signup/login endpoints
- **Api::V1::StreamsController**: Full CRUD with filtering and pinning
- **HealthController**: Health check endpoints

### Authentication & Authorization
- JWT-based authentication using custom implementation
- Pundit policies for role-based authorization
- Only editors and admins can create/modify streams

### Security
- Rack::Attack for rate limiting
- CORS configured for API access
- Strong parameter filtering
- Secure password requirements

### Testing
- RSpec configured with FactoryBot
- Example request specs for streams API
- Test database configuration

### Deployment
- Dockerfile for production builds
- docker compose.yml for local development
- Environment-specific configurations

## API Endpoints

### Authentication
- `POST /api/v1/users/signup` - Create new account
- `POST /api/v1/users/login` - Login

### Streams
- `GET /api/v1/streams` - List streams (with pagination)
- `GET /api/v1/streams/:id` - Show stream
- `POST /api/v1/streams` - Create stream (editors/admins only)
- `PUT /api/v1/streams/:id` - Update stream (owner or admin)
- `DELETE /api/v1/streams/:id` - Delete stream (owner or admin)
- `PUT /api/v1/streams/:id/pin` - Pin stream
- `DELETE /api/v1/streams/:id/pin` - Unpin stream

### Health Checks
- `GET /health` - Basic health check
- `GET /health/live` - Liveness probe
- `GET /health/ready` - Readiness probe (checks DB)

## Next Steps

1. Install Ruby 3.2+ or use Docker
2. Run database setup
3. Start the server
4. Test the API endpoints
5. Continue building additional features