# StreamSource Makefile
# Development shortcuts for Docker Compose commands
# All commands run inside Docker containers - no local Ruby/Rails required

# Color definitions
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
WHITE := \033[0;37m
BOLD := \033[1m
RESET := \033[0m

.PHONY: help dev up down restart logs shell console test spec lint rubocop migrate seed reset rebuild clean yarn assets routes

# Default target - show help
help:
	@echo "$(BOLD)$(BLUE)🚀 StreamSource Development Commands$(RESET)"
	@echo ""
	@echo "$(BOLD)$(GREEN)Core Commands:$(RESET)"
	@echo "  $(CYAN)make dev$(RESET)        - Start all services with asset watchers"
	@echo "  $(CYAN)make up$(RESET)         - Start core services only (no asset watchers)"
	@echo "  $(CYAN)make down$(RESET)       - Stop all services"
	@echo "  $(CYAN)make restart$(RESET)    - Restart all services"
	@echo "  $(CYAN)make logs$(RESET)       - Show logs (follow mode)"
	@echo "  $(CYAN)make status$(RESET)     - Show container status"
	@echo ""
	@echo "$(BOLD)$(GREEN)Development:$(RESET)"
	@echo "  $(CYAN)make shell$(RESET)      - Open bash shell in web container"
	@echo "  $(CYAN)make console$(RESET)    - Open Rails console"
	@echo "  $(CYAN)make routes$(RESET)     - Show Rails routes"
	@echo "  $(CYAN)make attach$(RESET)     - Attach to web container (for pry debugging)"
	@echo ""
	@echo "$(BOLD)$(GREEN)Testing:$(RESET)"
	@echo "  $(CYAN)make test$(RESET)       - Run full test suite (RSpec)"
	@echo "  $(CYAN)make spec$(RESET)       - Run specific test (use $(YELLOW)file=path/to/spec.rb$(RESET))"
	@echo "  $(CYAN)make coverage$(RESET)   - Open test coverage report"
	@echo ""
	@echo "$(BOLD)$(GREEN)Database:$(RESET)"
	@echo "  $(CYAN)make migrate$(RESET)    - Run database migrations"
	@echo "  $(CYAN)make rollback$(RESET)   - Rollback last migration"
	@echo "  $(CYAN)make seed$(RESET)       - Seed the database"
	@echo "  $(CYAN)make reset$(RESET)      - Reset database (drop, create, migrate, seed)"
	@echo "  $(CYAN)make db-console$(RESET) - Open PostgreSQL console"
	@echo ""
	@echo "$(BOLD)$(GREEN)Code Quality:$(RESET)"
	@echo "  $(CYAN)make lint$(RESET)       - Run RuboCop linter"
	@echo "  $(CYAN)make lint-fix$(RESET)   - Auto-fix RuboCop issues"
	@echo "  $(CYAN)make security$(RESET)   - Run Brakeman security analysis"
	@echo ""
	@echo "$(BOLD)$(GREEN)Assets:$(RESET)"
	@echo "  $(CYAN)make assets$(RESET)     - Build all assets (JS and CSS)"
	@echo "  $(CYAN)make watch-js$(RESET)   - Watch and rebuild JavaScript"
	@echo "  $(CYAN)make watch-css$(RESET)  - Watch and rebuild CSS"
	@echo ""
	@echo "$(BOLD)$(GREEN)Maintenance:$(RESET)"
	@echo "  $(CYAN)make rebuild$(RESET)    - Complete rebuild (clean + build + migrate + seed)"
	@echo "  $(CYAN)make clean$(RESET)      - Remove containers, volumes, and orphans"
	@echo "  $(CYAN)make install$(RESET)    - Install/update dependencies"

# Core Commands
# Start development environment with asset watchers
dev:
	docker compose --profile assets up -d
	@echo "$(BOLD)$(GREEN)✓ StreamSource is running!$(RESET)"
	@echo "$(YELLOW)- API:$(RESET) http://localhost:3000"
	@echo "$(YELLOW)- Admin:$(RESET) http://localhost:3000/admin"
	@echo "$(YELLOW)- API Docs:$(RESET) http://localhost:3000/api-docs"

# Start core services only (no asset watchers)
up:
	docker compose up -d
	@echo "$(BOLD)$(GREEN)✓ StreamSource core services are running$(RESET) $(YELLOW)(no asset watchers)$(RESET)"

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
		echo "$(RED)Error: No file specified$(RESET)"; \
		echo "$(YELLOW)Usage:$(RESET) make spec file=spec/models/stream_spec.rb"; \
		echo "$(YELLOW)   or:$(RESET) make spec file=spec/models/stream_spec.rb:42"; \
	else \
		docker compose exec web bin/test $(file); \
	fi

# Open test coverage report
coverage:
	@echo "$(BLUE)Opening coverage report...$(RESET)"
	@open coverage/index.html 2>/dev/null || xdg-open coverage/index.html 2>/dev/null || echo "$(YELLOW)Coverage report at:$(RESET) coverage/index.html"

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
		echo "$(RED)Error: No generator specified$(RESET)"; \
		echo "$(YELLOW)Usage:$(RESET) make generate what='model Stream title:string'"; \
		echo "$(YELLOW)   or:$(RESET) make generate what='controller Api::V1::Streams'"; \
		echo "$(YELLOW)   or:$(RESET) make generate what='migration AddIndexToStreams'"; \
	else \
		docker compose exec web bin/rails generate $(what); \
	fi

# Initial setup for new developers
setup:
	@echo "$(BOLD)$(BLUE)Setting up StreamSource development environment...$(RESET)"
	docker compose build
	docker compose up -d
	docker compose exec web bin/rails db:prepare
	@echo ""
	@echo "$(BOLD)$(GREEN)✓ Setup complete! StreamSource is running at:$(RESET)"
	@echo "$(YELLOW)- API:$(RESET) http://localhost:3000"
	@echo "$(YELLOW)- Admin:$(RESET) http://localhost:3000/admin $(PURPLE)(admin@example.com / Password123!)$(RESET)"
	@echo "$(YELLOW)- API Docs:$(RESET) http://localhost:3000/api-docs"

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
	@echo "$(BOLD)$(BLUE)Checking StreamSource health...$(RESET)"
	@docker compose ps
	@echo ""
	@echo "$(YELLOW)Rails status:$(RESET)"
	@docker compose exec web bin/rails runner "puts 'Rails: $(GREEN)OK$(RESET)' if true"
	@echo ""
	@echo "$(YELLOW)Database status:$(RESET)"
	@docker compose exec web bin/rails runner "puts 'Database: ' + (ActiveRecord::Base.connection.active? ? '$(GREEN)OK$(RESET)' : '$(RED)ERROR$(RESET)')"
	@echo ""
	@echo "$(YELLOW)Redis status:$(RESET)"
	@docker compose exec web bin/rails runner "puts 'Redis: ' + (Redis.new.ping == 'PONG' ? '$(GREEN)OK$(RESET)' : '$(RED)ERROR$(RESET)')"