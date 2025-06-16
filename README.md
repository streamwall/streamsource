# StreamSource

**🚀 Fully modernized in 2025 with TypeScript, Prisma ORM, Express 5, and enterprise-grade security.**

Streamsource is a publicly readable API to store and retrieve information about livestreams across many streaming platforms.

## Table of Contents
- [Overview](#overview)
- [Getting Started](#getting-started)
- [Installation](#installation)
- [Configuration](#configuration)
- [API Reference](#api-reference)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [Troubleshooting](#troubleshooting)

## Overview

**StreamSource** provides a centralized API for managing livestream information from multiple platforms including Facebook, Twitch, Instagram, and more. The API is publicly readable at [streams.streamwall.io](http://streams.streamwall.io) with authenticated write access for authorized users.

### Key Features
- 🌐 Multi-platform stream aggregation
- 🔍 Advanced filtering and search capabilities
- 🔒 JWT-based authentication with role-based access control
- 📌 Stream pinning to prevent automatic state changes
- ⏰ Automatic expiration tracking for inactive streams

### Current State
Streamsource is in active development at an early stage. The API is not yet stable and versioning has not been implemented. We welcome contributions!

### 🚀 Modernization Complete (2025)
The application has been fully modernized with current best practices:
- ✅ **Security**: All dependencies updated, Helmet.js, rate limiting, and input validation
- ✅ **Infrastructure**: Express 5, Docker support, GitHub Actions CI/CD
- ✅ **Type Safety**: Complete TypeScript conversion with strict typing
- ✅ **Database**: Prisma ORM with type-safe queries and migrations
- ✅ **Monitoring**: Prometheus metrics integration
- ✅ **Testing**: Full test suite migrated to TypeScript with Prisma mocks

See [CLAUDE.md](CLAUDE.md) for architecture details and development guidelines.

## Getting Started

**If you just want to use the API to read stream data**, see the [API Reference](#api-reference) section.

### Prerequisites

- Node.js (v20 LTS recommended)
- PostgreSQL (v15 or higher)
- Docker & Docker Compose (optional, for containerized development)
- LogDNA account (optional, for production logging)

### Quick Start

#### Using Docker (Recommended)

```bash
# Clone the repository
git clone https://github.com/streamwall/streamsource.git
cd streamsource

# Start the application with Docker Compose
docker-compose up

# The API will be available at http://localhost:3000
```

#### Manual Setup

```bash
# Clone the repository
git clone https://github.com/streamwall/streamsource.git
cd streamsource

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env 2>/dev/null || echo 'DATABASE_URL="postgresql://user:password@localhost:5432/streamsource"' > .env
echo 'JWT_SECRET="your-secret-key-change-in-production"' >> .env
# Edit .env with your configuration

# Generate Prisma client
npm run prisma:generate

# Run database migrations
npm run prisma:migrate

# Start the server
npm start
```

The API will be available at http://localhost:3000

## Installation

### Detailed Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/streamwall/streamsource.git
   cd streamsource
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up PostgreSQL**
   - Install PostgreSQL if not already installed
   - Create a database for the application
   - Create a database user with appropriate permissions
   ```sql
   CREATE DATABASE streamsource;
   CREATE USER streamsource_user WITH PASSWORD 'your_password';
   GRANT ALL PRIVILEGES ON DATABASE streamsource TO streamsource_user;
   ```

4. **Configure environment variables**
   ```bash
   cp example.env .env
   ```
   Edit `.env` with your configuration (see [Configuration](#configuration) section)

5. **Run database migrations**
   ```bash
   npx sequelize-cli db:migrate
   ```

6. **Set up LogDNA (Optional but recommended)**
   - Sign up for a LogDNA account
   - Obtain your ingestion key
   - Add it to your `.env` file

### Running the Application

```bash
# Development mode
npm start

# Or directly
node ./bin/www
```

The server will start on port 3000 (or the port specified in your environment variables).

### Upgrading

```bash
# Get latest code
git pull

# Install any new dependencies
npm install

# Run new migrations
npx sequelize-cli db:migrate

# Restart the server
npm start
```

## Configuration

### Environment Variables

Create a `.env` file in the root directory with the following variables:

```bash
# Server Configuration
PORT=3000                    # Port for the server (optional, defaults to 3000)

# Database Configuration
DB_USERNAME=your_db_user     # PostgreSQL username
DB_PASSWORD=your_db_password # PostgreSQL password
DB_NAME=streamsource        # Database name
DB_HOST=localhost           # Database host
DB_PORT=5432               # Database port (optional, defaults to 5432)
DB_DIALECT=postgres        # Database dialect (should be postgres)

# Authentication
JWT_SECRET=your_secret_key  # Secret key for JWT token signing (required)

# Logging
LOGDNA_INGESTION_KEY=your_key # LogDNA ingestion key (required for production)

# SSL Configuration
NODE_TLS_REJECT_UNAUTHORIZED=0 # Set to 0 for self-signed certificates (optional)
```

### Development and Contributing

This project is in active development. We welcome contributions!

Before contributing:
1. Read through existing issues and PRs
2. Follow the existing code style
3. Test your changes thoroughly
4. Update documentation as needed

For major changes, please open an issue first to discuss what you would like to change.

## API Reference

### Base URL
- Production: `https://streams.streamwall.io`
- Development: `http://localhost:3000`

### Authentication

The API uses JWT-based authentication with role-based access control.

#### User Roles
- **default**: Read-only access to public endpoints
- **editor**: Can create, read, update, and delete streams
- **admin**: Full access to all resources

#### Authentication Flow

1. **Create a user account**
   ```bash
   curl -d "email=youremail@yourdomain.com&password=abc123" -X POST http://localhost:3000/users/signup
   ```

2. **Obtain an authentication token**
   ```bash
   curl -d "email=youremail@yourdomain.com&password=abc123" -X POST http://localhost:3000/users/login
   ```

3. **Use the token in subsequent requests**
   ```bash
   curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3000/streams
   ```

⚠️ **Important**: Keep your token secure and never commit it to version control!

### POST /users/signup
Creates a new user

|Param|Description|
|-----|-----------|
|email|This will be your login|
|password|This will be your password|

#### Example:
```
curl -d "email=youremail@yourdomain.com&password=abc123" -X POST http://localhost:3000/users/signup
```
```json
{
    "message": "Signed up successfully",
    "user": {
        "role": "default",
        "id": 7,
        "email": "youremail@yourdomain.com",
        "password": "REDACTED",
        "updatedAt": "2020-09-25T06:38:05.045Z",
        "createdAt": "2020-09-25T06:38:05.045Z"
    }
}
```

**Note**: New users are assigned the `default` role. Contact an administrator to request `editor` or `admin` privileges.
### POST /users/login
Authenticate in order to retrieve a long-lived JWT that can be used to make requests to other endpoints.

|Param|Description|
|-----|-----------|
|email|The email address of a valid user|
|password|The password of a valid user|

#### Example:
```
curl -d "email=youremail@yourdomain.com&password=abc123" -X POST http://localhost:3000/users/login
```
```json
{
    "token": "YOURTOKEN"
}
```
### GET /streams
Retrieves a list of streams with the ability to filter results

Note: All string searches are case-insensitive and queried based on `ILIKE '%YOURSEARCHTERM%'`

|Param|Type|Description|
|-----|----|-----------|
|source|String|The name of a stream or streamer|
|notSource|String|The name of a stream or streamer to exclude|
|platform|String|The name of a streaming platform (e.g., "Facebook", "Twitch")|
|notPlatform|String|The name of a platform to exclude|
|link|String|The URL of a stream|
|status|String|One of: `['Live', 'Offline', 'Unknown']`|
|notStatus|String|Exclude this status. One of: `['Live', 'Offline', 'Unknown']`|
|isPinned|Boolean|Defaults to null. When true, prevents state changes, e.g. updates to `isExpired` or `status`|
|isExpired|Boolean|Streams are considered expired when they are no longer active. Default: false|
|title|String|Title of a stream|
|notTitle|String|Title of a stream|
|postedBy|String|Name of the person who submitted the link|
|notPostedBy|String|Name of a person to exclude|
|city|String|Name of a city|
|notCity|String|Name of a city to exclude|
|region|String|Name of a region (e.g., state, country, province)|
|notRegion|String|Name of a region (e.g., state, country, province) to exclude|
|createdAtFrom|Date|Filter streams created after this date (ISO 8601 format)|
|createdAtTo|Date|Filter streams created before this date (ISO 8601 format)|
|checkedAtFrom|Date|Filter streams checked after this date (ISO 8601 format)|
|checkedAtTo|Date|Filter streams checked before this date (ISO 8601 format)|
|liveAtFrom|Date|Filter streams that went live after this date (ISO 8601 format)|
|liveAtTo|Date|Filter streams that went live before this date (ISO 8601 format)|
|orderFields|String, CSV|CSV of fields to order by. Must be accompanied by an orderDirection for each field|
|orderDirections|String, CSV|CSV of directions to order by. One per orderField, respectively|
|format|String|Currently only accepts "`array`" or null; returns a raw array of streams for Streamwall if set to `array`, otherwise it's formatted like `{ data: [ {...}, {...} ] }`|

**Note**: There is a known bug where the `notStatus` parameter uses `req.query.status` instead of `req.query.notStatus`.

#### Example
Get all active streams in Seattle
```
curl http://localhost:3000/streams?city=seattle
```
```json
{
    "data": [
        {
            "id": 1,
            "source": "future_crystals",
            "platform": "Instagram",
            "link": "https://www.instagram.com/future_crystals/live",
            "status": "Live",
            "title": "",
            "isPinned": false,
            "isExpired": false,
            "checkedAt": "2020-09-25T04:58:52.840Z",
            "liveAt": "2020-09-25T04:58:52.840Z",
            "embedLink": "https://www.instagram.com/future_crystals/live",
            "postedBy": "someuser",
            "city": "Seattle",
            "region": "WA",
            "createdAt": "2020-09-25T04:58:52.840Z",
            "updatedAt": "2020-09-25T04:58:52.840Z"
        }
    ]
}
```

**Note**: When `format=array` is specified, the response will be a raw array without the `{ data: [...] }` wrapper.
### POST /streams
Create a new stream.
- **Requires authentication**
- **Requires privileged role: Editor or Admin**
```
 curl -d "link=http://someurl.com&city=Seattle&region=WA" -X POST http://localhost:3000/streams --header 'Authorization: Bearer MYTOKEN'
```
```json
{
    "data": {
        "id": 1,
        "source": "future_crystals",
        "platform": "Instagram",
        "link": "https://www.instagram.com/future_crystals/live",
        "status": "Live",
        "title": "",
        "isPinned": false,
        "isExpired": false,
        "checkedAt": "2020-09-25T04:58:52.840Z",
        "liveAt": "2020-09-25T04:58:52.840Z",
        "embedLink": "https://www.instagram.com/future_crystals/live",
        "postedBy": "someuser",
        "city": "Seattle",
        "region": "WA",
        "createdAt": "2020-09-25T04:58:52.840Z",
        "updatedAt": "2020-09-25T04:58:52.840Z"
    }
}
```

**Note**: If the stream already exists with the same link, the API returns a 303 status with the existing stream data.
### GET /streams/:id
Get details for a single stream
```
 curl http://localhost:3000/streams/1
```
```json
{
    "data": {
        "id": 1,
        "source": "future_crystals",
        "platform": "Instagram",
        "link": "https://www.instagram.com/future_crystals/live",
        "status": "Live",
        "title": "",
        "isPinned": false,
        "isExpired": false,
        "checkedAt": "2020-09-25T04:58:52.840Z",
        "liveAt": "2020-09-25T04:58:52.840Z",
        "embedLink": "https://www.instagram.com/future_crystals/live",
        "postedBy": "someuser",
        "city": "Seattle",
        "region": "WA",
        "createdAt": "2020-09-25T04:58:52.840Z",
        "updatedAt": "2020-09-25T04:58:52.840Z"
    }
}
```
### PATCH /streams/:id
Update a stream.
- **Requires authentication**
- **Requires privileged role: Editor or Admin**
```
 curl -d "status=Offline" -X PATCH http://localhost:3000/streams/1 --header 'Authorization: Bearer MYTOKEN'
```
```json
{
    "data": {
        "id": 1,
        "source": "future_crystals",
        "platform": "Instagram",
        "link": "https://www.instagram.com/future_crystals/live",
        "status": "Offline",
        "title": "",
        "isPinned": false,
        "isExpired": false,
        "checkedAt": "2020-09-25T04:58:52.840Z",
        "liveAt": "2020-09-25T04:58:52.840Z",
        "embedLink": "https://www.instagram.com/future_crystals/live",
        "postedBy": "someuser",
        "city": "Seattle",
        "region": "WA",
        "createdAt": "2020-09-25T04:58:52.840Z",
        "updatedAt": "2020-09-25T05:58:52.840Z"
    }
}
```
### DELETE /streams/:id
Expire a stream
- **Requires authentication**
- **Requires privileged role: Editor or Admin**
```
 curl -X DELETE http://localhost:3000/streams/1 --header 'Authorization: Bearer MYTOKEN'
```
```json
{
    "data": {
        "id": 1,
        "source": "future_crystals",
        "platform": "Instagram",
        "link": "https://www.instagram.com/future_crystals/live",
        "status": "Offline",
        "title": "",
        "isPinned": false,
        "isExpired": true,
        "checkedAt": "2020-09-25T04:58:52.840Z",
        "liveAt": "2020-09-25T04:58:52.840Z",
        "embedLink": "https://www.instagram.com/future_crystals/live",
        "postedBy": "someuser",
        "city": "Seattle",
        "region": "WA",
        "createdAt": "2020-09-25T04:58:52.840Z",
        "updatedAt": "2020-09-25T05:58:52.840Z"
    }
}
```
### PUT /streams/:id/pin
Pin a stream; prevents state changes while pinned
- **Requires authentication**
- **Requires privileged role: Editor or Admin**
```
 curl -X PUT http://localhost:3000/streams/1/pin --header 'Authorization: Bearer MYTOKEN'
```
```json
{
    "data": {
        "id": 1,
        "source": "future_crystals",
        "platform": "Instagram",
        "link": "https://www.instagram.com/future_crystals/live",
        "status": "Live",
        "title": "",
        "isPinned": true,
        "isExpired": false,
        "checkedAt": "2020-09-25T04:58:52.840Z",
        "liveAt": "2020-09-25T04:58:52.840Z",
        "embedLink": "https://www.instagram.com/future_crystals/live",
        "postedBy": "someuser",
        "city": "Seattle",
        "region": "WA",
        "createdAt": "2020-09-25T04:58:52.840Z",
        "updatedAt": "2020-09-25T05:58:52.840Z"
    }
}
```
### DELETE /streams/:id/pin
Unpin a stream
- **Requires authentication**
- **Requires privileged role: Editor or Admin**
```
 curl -X DELETE http://localhost:3000/streams/1/pin --header 'Authorization: Bearer MYTOKEN'
```
```json
{
    "data": {
        "id": 1,
        "source": "future_crystals",
        "platform": "Instagram",
        "link": "https://www.instagram.com/future_crystals/live",
        "status": "Live",
        "title": "",
        "isPinned": false,
        "isExpired": false,
        "checkedAt": "2020-09-25T04:58:52.840Z",
        "liveAt": "2020-09-25T04:58:52.840Z",
        "embedLink": "https://www.instagram.com/future_crystals/live",
        "postedBy": "someuser",
        "city": "Seattle",
        "region": "WA",
        "createdAt": "2020-09-25T04:58:52.840Z",
        "updatedAt": "2020-09-25T05:58:52.840Z"
    }
}
```

## Architecture

### Technology Stack

- **Framework**: Express.js 4.17.1
- **Database**: PostgreSQL with Sequelize ORM (v6.3.5)
- **Authentication**: JWT tokens with Passport.js
- **Logging**: Winston with LogDNA integration
- **View Engine**: Jade (legacy Pug)

### Project Structure

```
streamsource/
├── app.js                 # Main Express application setup
├── bin/www               # Server startup script
├── config/
│   └── config.js         # Database configuration
├── auth/
│   ├── authentication.js # Passport JWT strategy
│   └── authorization.js  # Role-based access control
├── models/
│   ├── index.js         # Sequelize initialization
│   ├── stream.js        # Stream model definition
│   └── user.js          # User model definition
├── routes/
│   ├── index.js         # Root route
│   ├── streams.js       # Stream API endpoints
│   └── users.js         # User authentication endpoints
├── migrations/          # Database migrations
├── middleware/
│   └── logger.js        # Winston logger configuration
├── public/              # Static assets
└── views/               # Jade templates
```

### Key Design Decisions

1. **JWT Authentication**: Stateless authentication for better scalability
2. **Role-Based Access Control**: Three-tier permission system (default, editor, admin)
3. **Stream Pinning**: Prevents automatic state changes for important streams
4. **Soft Deletes**: Streams are expired rather than deleted to maintain history
5. **Platform Agnostic**: Designed to support multiple streaming platforms

## Contributing

We welcome contributions! This project is in active development.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Style

- Follow existing code patterns
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

### Testing

Currently, the project does not have automated tests. When adding new features:
- Test all CRUD operations
- Verify authentication and authorization work correctly
- Check edge cases and error handling

## Troubleshooting

### Common Issues

#### Database Connection Errors
- Ensure PostgreSQL is running
- Verify database credentials in `.env`
- Check if the database exists and user has proper permissions

#### Authentication Errors
- Ensure JWT_SECRET is set in `.env`
- Verify token format: `Authorization: Bearer TOKEN`
- Check token expiration

#### LogDNA Errors
- Verify LOGDNA_INGESTION_KEY is correct
- The application will still run without LogDNA, but with reduced logging

### Error Codes

| Status Code | Description |
|-------------|-------------|
| 200 | Success |
| 201 | Created |
| 303 | See Other (duplicate stream) |
| 400 | Bad Request |
| 401 | Unauthorized (missing/invalid token) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found |
| 409 | Conflict (e.g., modifying pinned stream) |
| 500 | Internal Server Error |

### Known Issues

- The `notStatus` query parameter has a bug where it uses `req.query.status` instead of `req.query.notStatus`
- No API versioning implemented yet
- Limited error messages for better security (may make debugging harder)

### Getting Help

- Open an issue on GitHub for bugs or feature requests
- Check existing issues before creating new ones
- Provide detailed reproduction steps for bugs
