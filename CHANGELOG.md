# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-06-17

### Added
- Full-featured admin interface built with Hotwire (Turbo + Stimulus)
- Session-based authentication for admin users
- Real-time search with debouncing in admin interface
- Modal forms for seamless CRUD operations
- Tailwind CSS for modern, responsive design
- ESBuild for JavaScript bundling
- Pagy gem for efficient pagination in admin interface
- Asset pipeline configuration for JavaScript and CSS
- Admin-specific layouts and views
- Dedicated admin routes and controllers
- Development seed data with default admin user

### Changed
- Updated Dockerfile to include all gems (development, test, production)
- Fixed Docker bundle configuration issues
- Added Node.js and Yarn to Docker image for asset compilation
- Updated routes to support both API and HTML formats
- Enhanced README with admin interface documentation
- Improved development setup instructions

### Fixed
- Docker runtime issues with gem loading
- Bundle path configuration conflicts between host and container
- PostgreSQL health check in docker-compose.yml
- Flash message handling in Rails API mode
- Route helper generation for admin resources

### Security
- Added CSRF protection for admin forms
- Implemented session-based auth separate from JWT API
- Admin-only access controls for web interface

## [1.0.0] - 2024-01-16

### Added
- Initial Rails 8 API implementation
- JWT authentication system
- Role-based authorization (default, editor, admin)
- Stream management endpoints (CRUD operations)
- Pin/unpin functionality for streams
- Advanced filtering and pagination
- Rate limiting with Rack::Attack
- Health check endpoints for container orchestration
- Comprehensive test suite with 100% coverage goal
- Docker and Docker Compose configuration
- API documentation with examples
- Application constants configuration
- Feature flags system with Flipper
- OpenAPI/Swagger documentation
- Prometheus metrics endpoint

### Security
- JWT tokens with 24-hour expiration
- Strong password requirements
- Rate limiting on all endpoints
- Special throttling for authentication endpoints
- Input validation on all user inputs
- SQL injection prevention

### Changed
- Migrated from Node.js/Express to Rails 8
- Replaced Sequelize with ActiveRecord
- Replaced Passport.js with Devise + JWT
- Replaced Jest with RSpec for testing

### Removed
- Node.js application files
- Express dependencies
- Legacy authentication system