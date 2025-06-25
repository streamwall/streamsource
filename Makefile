# StreamSource Makefile
# Development shortcuts for Docker Compose commands
# All commands run inside Docker containers - no local Ruby/Rails required

.PHONY: help dev up down restart logs shell console test spec lint rubocop migrate seed reset rebuild clean yarn assets routes

# Default target - show help
help:
	@echo "StreamSource Development Commands:"
	@echo ""
	@echo "Core Commands:"
	@echo "  make dev        - Start all services with asset watchers"
	@echo "  make up         - Start core services only (no asset watchers)"
	@echo "  make down       - Stop all services"
	@echo "  make restart    - Restart all services"
	@echo "  make logs       - Show logs (follow mode)"
	@echo "  make status     - Show container status"
	@echo ""
	@echo "Development:"
	@echo "  make shell      - Open bash shell in web container"
	@echo "  make console    - Open Rails console"
	@echo "  make routes     - Show Rails routes"
	@echo "  make attach     - Attach to web container (for pry debugging)"
	@echo ""
	@echo "Testing:"
	@echo "  make test       - Run full test suite (RSpec)"
	@echo "  make spec       - Run specific test (use file=path/to/spec.rb)"
	@echo "  make coverage   - Open test coverage report"
	@echo ""
	@echo "Database:"
	@echo "  make migrate    - Run database migrations"
	@echo "  make rollback   - Rollback last migration"
	@echo "  make seed       - Seed the database"
	@echo "  make reset      - Reset database (drop, create, migrate, seed)"
	@echo "  make db-console - Open PostgreSQL console"
	@echo ""
	@echo "Code Quality:"
	@echo "  make lint       - Run RuboCop linter"
	@echo "  make lint-fix   - Auto-fix RuboCop issues"
	@echo "  make security   - Run Brakeman security analysis"
	@echo ""
	@echo "Assets:"
	@echo "  make assets     - Build all assets (JS and CSS)"
	@echo "  make watch-js   - Watch and rebuild JavaScript"
	@echo "  make watch-css  - Watch and rebuild CSS"
	@echo ""
	@echo "Maintenance:"
	@echo "  make rebuild    - Complete rebuild (clean + build + migrate + seed)"
	@echo "  make clean      - Remove containers, volumes, and orphans"
	@echo "  make install    - Install/update dependencies"

# Core Commands
# Start development environment with asset watchers
dev:
	docker compose --profile assets up -d
	@echo "StreamSource is running!"
	@echo "- API: http://localhost:3000"
	@echo "- Admin: http://localhost:3000/admin"
	@echo "- API Docs: http://localhost:3000/api-docs"

# Start core services only (no asset watchers)
up:
	docker compose up -d
	@echo "StreamSource core services are running (no asset watchers)"

# Stop all services
down:
	docker compose down

# Restart all services
restart: down dev

# Show logs in follow mode
logs:
	docker compose logs -f web

# Show container status
status:
	docker compose ps

# Development Tools
# Open bash shell in web container
shell:
	docker compose exec web bash

# Open Rails console
console:
	docker compose exec web bin/rails console

# Show Rails routes
routes:
	docker compose exec web bin/rails routes

# Attach to web container (for pry debugging)
attach:
	docker attach $$(docker compose ps -q web)

# Testing
# Run full test suite using RSpec
test:
	docker compose exec web bin/test

# Run specific test file
spec:
	@if [ -z "$(file)" ]; then \
		echo "Usage: make spec file=spec/models/stream_spec.rb"; \
		echo "   or: make spec file=spec/models/stream_spec.rb:42"; \
	else \
		docker compose exec web bin/test $(file); \
	fi

# Open test coverage report
coverage:
	@echo "Opening coverage report..."
	@open coverage/index.html 2>/dev/null || xdg-open coverage/index.html 2>/dev/null || echo "Coverage report at: coverage/index.html"

# Database Management
# Run database migrations
migrate:
	docker compose exec web bin/rails db:migrate

# Rollback last migration
rollback:
	docker compose exec web bin/rails db:rollback

# Seed the database
seed:
	docker compose exec web bin/rails db:seed

# Reset database (drop, create, migrate, seed)
reset:
	docker compose exec web bin/rails db:reset

# Open PostgreSQL console
db-console:
	docker compose exec db psql -U streamsource

# Code Quality
# Run RuboCop linter
lint:
	docker compose exec web bin/rubocop

# Auto-fix RuboCop issues
lint-fix:
	docker compose exec web bundle exec rubocop -A

# Run Brakeman security analysis
security:
	docker compose exec web bin/brakeman

# Asset Management
# Build all assets (JavaScript and CSS)
assets:
	docker compose exec web yarn build
	docker compose exec web yarn build:css

# Watch and rebuild JavaScript
watch-js:
	docker compose exec web yarn build --watch

# Watch and rebuild CSS
watch-css:
	docker compose exec web yarn build:css --watch

# Maintenance
# Complete rebuild - equivalent to dcnuke alias
rebuild:
	docker compose stop
	docker compose down -v --remove-orphans
	docker compose up -d
	docker compose run --rm web yarn build
	docker compose run --rm web yarn build:css
	docker compose exec web bin/rails db:prepare
	docker compose logs -f web

# Clean up everything (containers, volumes, orphans)
clean:
	docker compose down -v --remove-orphans

# Install/update dependencies
install:
	docker compose exec web bundle install
	docker compose exec web yarn install

# Additional Commands
.PHONY: redis-cli cache-clear db-prepare generate setup

# Access Redis CLI
redis-cli:
	docker compose exec redis redis-cli

# Clear Rails cache
cache-clear:
	docker compose exec web bin/rails cache:clear

# Prepare database (create if needed, migrate, seed)
db-prepare:
	docker compose exec web bin/rails db:prepare

# Rails generators
generate:
	@if [ -z "$(what)" ]; then \
		echo "Usage: make generate what='model Stream title:string'"; \
		echo "   or: make generate what='controller Api::V1::Streams'"; \
		echo "   or: make generate what='migration AddIndexToStreams'"; \
	else \
		docker compose exec web bin/rails generate $(what); \
	fi

# Initial setup for new developers
setup:
	@echo "Setting up StreamSource development environment..."
	docker compose build
	docker compose up -d
	docker compose exec web bin/rails db:prepare
	@echo ""
	@echo "Setup complete! StreamSource is running at:"
	@echo "- API: http://localhost:3000"
	@echo "- Admin: http://localhost:3000/admin (admin@example.com / Password123!)"
	@echo "- API Docs: http://localhost:3000/api-docs"

# Utility Commands
.PHONY: exec run yarn bundle

# Execute command in web container
exec:
	@if [ -z "$(cmd)" ]; then \
		echo "Usage: make exec cmd='ls -la'"; \
	else \
		docker compose exec web $(cmd); \
	fi

# Run command in new web container
run:
	@if [ -z "$(cmd)" ]; then \
		echo "Usage: make run cmd='rake db:version'"; \
	else \
		docker compose run --rm web $(cmd); \
	fi

# Run yarn commands
yarn:
	@if [ -z "$(cmd)" ]; then \
		echo "Usage: make yarn cmd='add lodash'"; \
	else \
		docker compose exec web yarn $(cmd); \
	fi

# Run bundle commands
bundle:
	@if [ -z "$(cmd)" ]; then \
		echo "Usage: make bundle cmd='add rspec-rails'"; \
	else \
		docker compose exec web bundle $(cmd); \
	fi

# Troubleshooting
.PHONY: logs-all logs-web logs-db ps-all health

# Show logs for all services
logs-all:
	docker compose logs -f

# Show only web logs
logs-web:
	docker compose logs -f web

# Show only database logs
logs-db:
	docker compose logs -f db

# Show all containers (including stopped)
ps-all:
	docker compose ps -a

# Health check
health:
	@echo "Checking StreamSource health..."
	@docker compose ps
	@echo ""
	@echo "Rails status:"
	@docker compose exec web bin/rails runner "puts 'Rails: OK'"
	@echo ""
	@echo "Database status:"
	@docker compose exec web bin/rails runner "puts 'Database: ' + (ActiveRecord::Base.connection.active? ? 'OK' : 'ERROR')"
	@echo ""
	@echo "Redis status:"
	@docker compose exec web bin/rails runner "puts 'Redis: ' + (Redis.new.ping == 'PONG' ? 'OK' : 'ERROR')"