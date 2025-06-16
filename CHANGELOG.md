# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- Replaced Passport.js with custom JWT implementation
- Replaced Jest with RSpec for testing

### Removed
- Node.js application files
- Express dependencies
- Legacy authentication system