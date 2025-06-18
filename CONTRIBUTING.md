# Contributing to StreamSource

Thank you for your interest in contributing to StreamSource! This guide will help you get started.

## Development Environment

> **IMPORTANT**: This project runs exclusively in Docker containers. Do not use system Ruby, Bundler, or any local development tools. All commands must be executed within the Docker environment.

## Getting Started

1. **Fork and Clone**
   ```bash
   git clone https://github.com/yourusername/streamsource.git
   cd streamsource
   ```

2. **Start Docker Services**
   ```bash
   docker compose up -d
   ```

3. **Verify Everything is Running**
   ```bash
   docker compose ps
   docker compose logs -f web
   ```

## Development Workflow

### 1. Create a Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes

Remember to:
- Write tests first (TDD/BDD approach)
- Follow existing code patterns and conventions
- Keep controllers thin, models fat
- Use service objects for complex business logic
- Update documentation as needed

### 3. Run Tests

All tests must pass before submitting a PR:

```bash
# Run all tests
docker compose exec web bin/test

# Run specific test file
docker compose exec web bin/test spec/models/stream_spec.rb

# Run tests with specific line number
docker compose exec web bin/test spec/models/stream_spec.rb:42
```

### 4. Check Code Style

```bash
# Run RuboCop
docker compose exec web bundle exec rubocop

# Auto-fix issues
docker compose exec web bundle exec rubocop -A
```

### 5. Test Your Changes Manually

```bash
# Access Rails console
docker compose exec web bin/rails console

# View logs
docker compose logs -f web

# Access the application
# API: http://localhost:3000
# Admin: http://localhost:3000/admin
# API Docs: http://localhost:3000/api-docs
```

## Common Development Tasks

### Adding a New Gem

1. Edit the `Gemfile`
2. Rebuild the Docker image:
   ```bash
   docker compose build web
   ```
3. Restart services:
   ```bash
   docker compose restart web
   ```

### Running Database Migrations

```bash
# Create a new migration
docker compose exec web bin/rails generate migration AddFieldToModel field:type

# Run migrations
docker compose exec web bin/rails db:migrate

# Rollback if needed
docker compose exec web bin/rails db:rollback
```

### Debugging

```bash
# Add binding.pry or debugger to your code
# Attach to the container
docker attach streamsource_web_1

# Or view logs
docker compose logs -f web
```

### Working with Assets

```bash
# Rebuild JavaScript
docker compose exec web yarn build

# Rebuild CSS
docker compose exec web yarn build:css

# Watch mode for development
docker compose exec web yarn build --watch
docker compose exec web yarn build:css --watch
```

## Testing Guidelines

1. **Write Tests First**: Follow TDD/BDD practices
2. **Test Coverage**: Aim for high test coverage (current: ~78%)
3. **Test Types**:
   - Model specs for business logic
   - Request specs for API endpoints
   - System specs for admin interface
   - Policy specs for authorization

### Running Specific Test Types

```bash
# Model tests only
docker compose exec web bin/test spec/models

# Controller tests only
docker compose exec web bin/test spec/controllers

# Request tests only
docker compose exec web bin/test spec/requests
```

## Code Style Guide

- Follow Ruby community standards
- Use RuboCop with Rails Omakase configuration
- Keep methods small and focused
- Write descriptive variable and method names
- Add comments for complex logic
- Use constants from `ApplicationConstants` module

## Submitting a Pull Request

1. **Ensure all tests pass**
   ```bash
   docker compose exec web bin/test
   ```

2. **Check code style**
   ```bash
   docker compose exec web bundle exec rubocop
   ```

3. **Update documentation**
   - Update README.md if adding new features
   - Update CLAUDE.md if changing architecture
   - Add/update code comments as needed

4. **Write a good commit message**
   ```
   feat: Add stream analytics endpoint
   
   - Add /api/v1/streams/:id/analytics endpoint
   - Include view count and unique viewers
   - Add feature flag for gradual rollout
   - Update API documentation
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **PR Description Template**
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update
   
   ## Testing
   - [ ] All tests pass
   - [ ] Added new tests
   - [ ] Manual testing completed
   
   ## Checklist
   - [ ] Code follows project style
   - [ ] Self-review completed
   - [ ] Documentation updated
   - [ ] No new warnings
   ```

## Need Help?

- Check existing issues and PRs
- Review the codebase for examples
- Ask questions in your PR
- Refer to CLAUDE.md for architecture details

## Docker Troubleshooting

### Container won't start
```bash
# Check logs
docker compose logs web

# Rebuild from scratch
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

### Permission issues
```bash
# Fix ownership if needed
docker compose exec web chown -R $(id -u):$(id -g) .
```

### Out of space
```bash
# Clean up Docker
docker system prune -a
```

Remember: All development happens in Docker. Never install Ruby, Bundler, or gems on your host system!