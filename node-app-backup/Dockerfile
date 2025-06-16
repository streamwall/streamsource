# Use Node.js LTS Alpine image for smaller size
FROM node:20-alpine AS base

# Install production dependencies
FROM base AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Install all dependencies for building
FROM base AS dev-deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Build the application
FROM dev-deps AS build
WORKDIR /app
COPY . .
RUN npm run build || true

# Production image
FROM base AS runtime
WORKDIR /app

# Copy production dependencies
COPY --from=deps /app/node_modules ./node_modules

# Copy application code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001
USER nodejs

# Expose port
EXPOSE 3000

# Start the application
CMD ["node", "bin/www"]