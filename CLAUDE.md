# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

- **Start server**: `npm start` or `node ./bin/www` - Runs on port 3000 (or PORT env variable)
- **Run migrations**: `npx sequelize-cli db:migrate` - Apply database schema changes
- **Database setup**: Requires PostgreSQL installation and .env configuration

## Architecture Overview

StreamSource is an Express.js API for managing livestream information across multiple platforms. Key architectural patterns:

### Authentication & Authorization
- JWT-based authentication implemented via Passport.js in `auth/authentication.js`
- Role-based access control (default, Editor, Admin) in `auth/authorization.js`
- Protected endpoints require Bearer token in Authorization header

### Database Layer
- Sequelize ORM with PostgreSQL
- Models in `models/` directory define Stream and User entities
- Stream model includes pinning functionality (`isPinned`) to prevent state changes
- Migrations in `migrations/` handle schema evolution

### API Structure
- RESTful endpoints in `routes/` directory
- Stream operations support complex filtering via query parameters
- Public read access, authenticated write access for Editor/Admin roles

### Logging
- Winston logger configured in `middleware/logger.js`
- Integrates with LogDNA for production logging

### Recent Features
- Stream pinning prevents automatic expiration or status changes
- Editor/Admin role requirement for stream creation
- Complex query filtering on streams endpoint