# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🚀 Modernization Context (Updated 2025)

This codebase is being modernized from a 2020-era Express 4 application to follow 2025 best practices:

### Completed Modernizations
- ✅ Express 5 (native async/await error handling)
- ✅ All dependencies updated to latest secure versions
- ✅ Security middleware (Helmet, rate limiting, input validation)
- ✅ TypeScript setup with gradual migration path
- ✅ Docker containerization
- ✅ Jade → Pug template migration
- ✅ TypeScript migration completed - all core files converted
- ✅ Prisma schema created with full compatibility layer
- ✅ CI/CD with GitHub Actions
- ✅ Prometheus metrics integration

### Completed Work
- ✅ All tests migrated to TypeScript with Prisma mocks
- ✅ Full TypeScript/Prisma implementation
- ✅ Sequelize completely removed from the project
- ✅ All dependencies updated and cleaned up

### Ready to Deploy
The application is now fully modernized and ready for deployment. To get started:
1. Set up your PostgreSQL database
2. Configure `.env` with your `DATABASE_URL`
3. Run `npm run prisma:migrate` to create the database schema
4. Start the application with `npm start`

### Architecture Decisions
- **Staying with Node.js**: Express 5 fixes previous pain points; Node.js ecosystem remains strong
- **Prisma over Sequelize**: Better TypeScript support and modern DX
- **Docker-first**: Prevents dependency drift over time
- **Gradual migration**: Reducing risk while improving the codebase

## Development Commands

### Running the Application
- **Docker (recommended)**: `docker-compose up` - Starts app and PostgreSQL
- **Local development**: `npm run dev` - Uses nodemon for auto-reload
- **Production**: `npm start` or `node ./bin/www` - Runs on port 3000 (or PORT env)

### Database Management
- **Prisma Commands**:
  - `npm run prisma:generate` - Generate Prisma Client
  - `npm run prisma:migrate` - Create and apply migrations
  - `npm run prisma:studio` - Visual database browser
  - `npx prisma db push` - Push schema changes without migrations (dev only)
  - `npx prisma migrate deploy` - Apply migrations in production

### Testing
- **Run all tests**: `npm test`
- **With coverage**: `npm run test:coverage`
- **Specific suite**: `npm test -- tests/routes/streams.test.js`

### Build & Type Checking
- **TypeScript build**: `npm run build`
- **Watch mode**: `npm run build:watch`
- **Type checking**: `npm run typecheck`

### Important Notes
- **JWT_SECRET**: Required environment variable for authentication
- **Tests**: Currently failing due to TypeScript/Prisma migration - needs refactoring

## Architecture Overview

StreamSource is an Express.js API for managing livestream information across multiple platforms. Key architectural patterns:

### Authentication & Authorization
- JWT-based authentication implemented via Passport.js in `auth/authentication.js`
- Role-based access control (default, Editor, Admin) in `auth/authorization.js`
- Protected endpoints require Bearer token in Authorization header

### Database Layer
- **Prisma ORM** with PostgreSQL (migrated from Sequelize)
- Schema defined in `prisma/schema.prisma`
- Models: User and Stream with full type safety
- Stream model includes pinning functionality (`isPinned`) to prevent state changes
- Client extensions in `lib/prisma.ts` handle password hashing and location inference

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