# StreamSource API & Admin Interface Makefile
# Development shortcuts for Docker Compose commands
# All commands run inside Docker containers - no local Ruby/Node.js required

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

.PHONY: help dev up down restart logs shell test lint migrate seed reset rebuild clean bundle yarn

# Default target - show help
help:
	@echo "$(BOLD)$(BLUE)🚀 StreamSource API & Admin Interface Development Commands$(RESET)"
	@echo ""
	@echo "$(BOLD)$(GREEN)Core Commands:$(RESET)"
	@echo "  $(CYAN)make dev$(RESET)         - Start in development mode with auto-reload"
	@echo "  $(CYAN)make up$(RESET)          - Start services in background"
	@echo "  $(CYAN)make down$(RESET)        - Stop all services"
	@echo "  $(CYAN)make restart$(RESET)     - Restart all services"
	@echo "  $(CYAN)make logs$(RESET)        - Show logs (follow mode)"
	@echo "  $(CYAN)make status$(RESET)      - Show container status"
	@echo ""
	@echo "$(BOLD)$(GREEN)Development:$(RESET)"
	@echo "  $(CYAN)make shell$(RESET)       - Open bash shell in web container"
	@echo "  $(CYAN)make rails$(RESET)       - Open Rails console"
	@echo "  $(CYAN)make attach$(RESET)      - Attach to container (for debugging)"
	@echo "  $(CYAN)make local$(RESET)       - Run locally with Rails server"
	@echo "  $(CYAN)make debug$(RESET)       - Start with debug logging"
	@echo ""
	@echo "$(BOLD)$(GREEN)Database & Data:$(RESET)"
	@echo "  $(CYAN)make migrate$(RESET)     - Run database migrations"
	@echo "  $(CYAN)make rollback$(RESET)    - Rollback last migration"
	@echo "  $(CYAN)make seed$(RESET)        - Seed database with sample data"
	@echo "  $(CYAN)make reset$(RESET)       - Reset database (drop, create, migrate, seed)"
	@echo "  $(CYAN)make db-shell$(RESET)    - Open PostgreSQL shell"
	@echo ""
	@echo "$(BOLD)$(GREEN)Testing:$(RESET)"
	@echo "  $(CYAN)make test$(RESET)        - Run full test suite with coverage"
	@echo "  $(CYAN)make test-watch$(RESET)  - Run tests in watch mode"
	@echo "  $(CYAN)make test-models$(RESET) - Run model tests only"
	@echo "  $(CYAN)make test-requests$(RESET) - Run request/API tests only"
	@echo "  $(CYAN)make test-features$(RESET) - Run feature/system tests only"
	@echo "  $(CYAN)make test-parallel$(RESET) - Run tests in parallel (faster)"
	@echo "  $(CYAN)make coverage$(RESET)    - Open test coverage report"
	@echo ""
	@echo "$(BOLD)$(GREEN)Code Quality & Linting:$(RESET)"
	@echo "  $(CYAN)make lint$(RESET)        - Run comprehensive linting"
	@echo "  $(CYAN)make lint-fix$(RESET)    - Auto-fix all linting issues"
	@echo "  $(CYAN)make lint-check$(RESET)  - Strict linting (no warnings allowed)"
	@echo "  $(CYAN)make lint-ruby$(RESET)   - Ruby code style only (RuboCop)"
	@echo "  $(CYAN)make lint-js$(RESET)     - JavaScript code style only (ESLint)"
	@echo "  $(CYAN)make format$(RESET)      - Format code (alias for lint-fix)"
	@echo "  $(CYAN)make quality$(RESET)     - Code quality metrics & comprehensive check"
	@echo "  $(CYAN)make pre-commit$(RESET)  - Full pre-commit validation"
	@echo ""
	@echo "$(BOLD)$(GREEN)Assets & Dependencies:$(RESET)"
	@echo "  $(CYAN)make assets$(RESET)      - Compile assets for production"
	@echo "  $(CYAN)make assets-dev$(RESET)  - Compile assets for development"
	@echo "  $(CYAN)make bundle$(RESET)      - Install Ruby gems"
	@echo "  $(CYAN)make yarn$(RESET)        - Install JavaScript dependencies"
	@echo "  $(CYAN)make install$(RESET)     - Install all dependencies (bundle + yarn)"
	@echo "  $(CYAN)make update$(RESET)      - Update all dependencies"
	@echo ""
	@echo "$(BOLD)$(GREEN)Configuration:$(RESET)"
	@echo "  $(CYAN)make setup$(RESET)       - Initial setup (create .env, install deps)"
	@echo "  $(CYAN)make env-check$(RESET)   - Validate environment configuration"
	@echo "  $(CYAN)make config$(RESET)      - Show current configuration (sanitized)"
	@echo "  $(CYAN)make routes$(RESET)      - Show all Rails routes"
	@echo "  $(CYAN)make backup$(RESET)      - Backup configuration and database"
	@echo ""
	@echo "$(BOLD)$(GREEN)Security & Maintenance:$(RESET)"
	@echo "  $(CYAN)make security$(RESET)    - Security audit and secret scanning"
	@echo "  $(CYAN)make rebuild$(RESET)     - Complete rebuild (clean + build + start)"
	@echo "  $(CYAN)make clean$(RESET)       - Remove containers, volumes, and logs"
	@echo "  $(CYAN)make clean-all$(RESET)   - Deep clean (including images and cache)"
	@echo "  $(CYAN)make prune$(RESET)       - Remove unused Docker resources"
	@echo ""
	@echo "$(BOLD)$(GREEN)Troubleshooting:$(RESET)"
	@echo "  $(CYAN)make health$(RESET)      - System health check"
	@echo "  $(CYAN)make doctor$(RESET)      - Diagnose common issues"
	@echo "  $(CYAN)make logs-file$(RESET)   - Show application log file"
	@echo "  $(CYAN)make version$(RESET)     - Show version information"
	@echo ""
	@echo "$(BOLD)$(GREEN)Quick Shortcuts:$(RESET)"
	@echo "  $(CYAN)make d$(RESET) = dev, $(CYAN)make u$(RESET) = up, $(CYAN)make l$(RESET) = logs, $(CYAN)make r$(RESET) = restart, $(CYAN)make s$(RESET) = status, $(CYAN)make c$(RESET) = rails"

# Core Commands
# Start development environment with auto-reload
dev:
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)⚠️  No .env file found. Running setup first...$(RESET)"; \
		$(MAKE) setup; \
	fi
	@echo "$(BOLD)$(BLUE)🚀 Starting StreamSource in development mode...$(RESET)"
	docker compose up
	@echo "$(BOLD)$(GREEN)✓ StreamSource is running!$(RESET)"
	@echo "$(YELLOW)Admin Interface:$(RESET) http://localhost:3000/admin"
	@echo "$(YELLOW)API Documentation:$(RESET) http://localhost:3000/api-docs"
	@echo "$(YELLOW)Check logs with:$(RESET) make logs"

# Start services in background
up:
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)⚠️  No .env file found. Running setup first...$(RESET)"; \
		$(MAKE) setup; \
	fi
	@echo "$(BOLD)$(BLUE)🚀 Starting services in background...$(RESET)"
	docker compose up -d
	@echo "$(BOLD)$(GREEN)✓ StreamSource is running in background$(RESET)"
	@echo "$(YELLOW)Check status with:$(RESET) make status"
	@echo "$(YELLOW)View logs with:$(RESET) make logs"

# Stop all services
down:
	@echo "$(YELLOW)Stopping all services...$(RESET)"
	docker compose down
	@echo "$(GREEN)✓ Services stopped$(RESET)"

# Restart all services
restart: down dev

# Show logs in follow mode
logs:
	@echo "$(CYAN)Following application logs... (Ctrl+C to exit)$(RESET)"
	docker compose logs -f

# Show container status
status:
	@echo "$(CYAN)Container Status:$(RESET)"
	docker compose ps

# Development Tools
# Open bash shell in web container
shell:
	@echo "$(CYAN)Opening shell in web container...$(RESET)"
	docker compose exec web bash

# Open Rails console
rails:
	@echo "$(CYAN)Opening Rails console...$(RESET)"
	docker compose exec web bin/rails console

# Attach to container (for debugging)
attach:
	@echo "$(CYAN)Attaching to web container... (Ctrl+P, Ctrl+Q to detach)$(RESET)"
	docker attach $$(docker compose ps -q web)

# Run locally with Rails server
local:
	@echo "$(CYAN)Running locally with Rails server...$(RESET)"
	@echo "$(YELLOW)⚠️  This requires local Ruby 3.3.6 and dependencies$(RESET)"
	bin/rails server

# Start with debug logging
debug:
	@echo "$(CYAN)Starting with debug logging enabled...$(RESET)"
	RAILS_LOG_LEVEL=debug docker compose up

# Database & Data Management
# Run database migrations
migrate:
	@echo "$(BOLD)$(CYAN)🗄️  Running database migrations...$(RESET)"
	docker compose exec web bin/rails db:migrate
	@echo "$(GREEN)✓ Migrations completed$(RESET)"

# Rollback last migration
rollback:
	@echo "$(BOLD)$(YELLOW)⏪ Rolling back last migration...$(RESET)"
	docker compose exec web bin/rails db:rollback
	@echo "$(GREEN)✓ Rollback completed$(RESET)"

# Seed database with sample data
seed:
	@echo "$(BOLD)$(CYAN)🌱 Seeding database with sample data...$(RESET)"
	docker compose exec web bin/rails db:seed
	@echo "$(GREEN)✓ Database seeded$(RESET)"

# Reset database (drop, create, migrate, seed)
reset:
	@echo "$(BOLD)$(RED)🔄 Resetting database (this will destroy all data)...$(RESET)"
	@read -p "Are you sure? (y/N) " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo ""; \
		docker compose exec web bin/rails db:reset; \
		echo "$(GREEN)✓ Database reset completed$(RESET)"; \
	else \
		echo "$(YELLOW)Database reset cancelled$(RESET)"; \
	fi

# Open PostgreSQL shell
db-shell:
	@echo "$(CYAN)Opening PostgreSQL shell...$(RESET)"
	docker compose exec db psql -U streamsource

# Testing
# Run full test suite with coverage
test:
	@echo "$(BOLD)$(CYAN)🧪 Running full test suite with coverage...$(RESET)"
	docker compose exec web bin/test
	@echo "$(GREEN)✓ Tests completed$(RESET)"

# Run tests in watch mode
test-watch:
	@echo "$(BOLD)$(CYAN)🔍 Running tests in watch mode...$(RESET)"
	docker compose exec web bundle exec guard

# Open test coverage report
coverage:
	@echo "$(BLUE)Opening coverage report...$(RESET)"
	@if [ -f coverage/index.html ]; then \
		open coverage/index.html 2>/dev/null || xdg-open coverage/index.html 2>/dev/null || echo "$(YELLOW)Coverage report at:$(RESET) coverage/index.html"; \
	else \
		echo "$(RED)Coverage report not found. Run 'make test' first.$(RESET)"; \
	fi

# Run model tests only
test-models:
	@echo "$(BOLD)$(CYAN)🏗️  Running model tests...$(RESET)"
	docker compose exec web bin/test spec/models/

# Run request/API tests only
test-requests:
	@echo "$(BOLD)$(CYAN)🌐 Running request/API tests...$(RESET)"
	docker compose exec web bin/test spec/requests/

# Run feature/system tests only
test-features:
	@echo "$(BOLD)$(CYAN)🎭 Running feature/system tests...$(RESET)"
	docker compose exec web bin/test spec/features/ spec/system/

# Run tests in parallel (faster)
test-parallel:
	@echo "$(BOLD)$(CYAN)⚡ Running tests in parallel...$(RESET)"
	docker compose exec web bundle exec parallel_rspec spec/

# Code Quality & Linting
# Run comprehensive linting
lint:
	@echo "$(BOLD)$(BLUE)🔍 Running Comprehensive Code Analysis$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)Ruby Code Style (RuboCop)$(RESET)"
	@docker compose exec web bundle exec rubocop --format=progress --display-cop-names || echo "$(RED)❌ RuboCop found issues$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)JavaScript Code Style (ESLint)$(RESET)"
	@docker compose exec web yarn run lint || echo "$(RED)❌ ESLint found issues$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)Security Analysis (Brakeman)$(RESET)"
	@docker compose exec web bundle exec brakeman -q --no-progress || echo "$(RED)❌ Brakeman found security issues$(RESET)"
	@echo ""
	@echo "$(BOLD)$(GREEN)✅ Linting complete! Check output above for any issues.$(RESET)"

# Auto-fix all linting issues
lint-fix:
	@echo "$(BOLD)$(BLUE)🔧 Auto-fixing Code Issues$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)Auto-fixing Ruby issues...$(RESET)"
	@docker compose exec web bundle exec rubocop --auto-correct-all || true
	@echo ""
	@echo "$(BOLD)$(YELLOW)Auto-fixing JavaScript issues...$(RESET)"
	@docker compose exec web yarn run lint:fix || true
	@echo ""
	@echo "$(BOLD)$(GREEN)✅ Auto-fix complete! Run 'make lint' to check remaining issues.$(RESET)"

# Strict linting (no warnings allowed)
lint-check:
	@echo "$(BOLD)$(CYAN)🚨 Running strict linting (no warnings allowed)...$(RESET)"
	@docker compose exec web bundle exec rubocop --format=quiet || (echo "$(RED)❌ RuboCop issues found$(RESET)" && exit 1)
	@docker compose exec web yarn run lint:check || (echo "$(RED)❌ ESLint issues found$(RESET)" && exit 1)
	@echo "$(BOLD)$(GREEN)✅ Code quality check passed!$(RESET)"

# Ruby-only linting
lint-ruby:
	@echo "$(BOLD)$(YELLOW)Ruby Code Analysis$(RESET)"
	@docker compose exec web bundle exec rubocop --format=progress --display-cop-names

# JavaScript-only linting
lint-js:
	@echo "$(BOLD)$(YELLOW)JavaScript Code Analysis$(RESET)"
	@docker compose exec web yarn run lint

# Format code (alias for lint-fix)
format: lint-fix

# Code quality metrics & comprehensive check
quality:
	@echo "$(BOLD)$(BLUE)📊 Comprehensive Quality Check$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)Step 1: Code linting...$(RESET)"
	@$(MAKE) lint-check --no-print-directory
	@echo ""
	@echo "$(BOLD)$(YELLOW)Step 2: Running tests...$(RESET)"
	@$(MAKE) test --no-print-directory
	@echo ""
	@echo "$(BOLD)$(YELLOW)Step 3: Code metrics...$(RESET)"
	@echo "$(CYAN)Lines of Code:$(RESET)"
	@find app -name '*.rb' -exec wc -l {} + | tail -1 | awk '{print "Ruby: " $$1 " lines"}' 2>/dev/null || echo "Ruby: 0 lines"
	@find app/javascript -name '*.js' -exec wc -l {} + | tail -1 | awk '{print "JavaScript: " $$1 " lines"}' 2>/dev/null || echo "JavaScript: 0 lines"
	@echo ""
	@echo "$(CYAN)File Counts:$(RESET)"
	@echo "Models: $$(find app/models -name '*.rb' | wc -l | tr -d ' ')"
	@echo "Controllers: $$(find app/controllers -name '*.rb' | wc -l | tr -d ' ')"
	@echo "Views: $$(find app/views -name '*.erb' | wc -l | tr -d ' ')"
	@echo "Tests: $$(find spec -name '*_spec.rb' | wc -l | tr -d ' ')"
	@echo "Config files: $$(find config -name '*.rb' -o -name '*.yml' | wc -l | tr -d ' ')"
	@echo ""
	@echo "$(BOLD)$(GREEN)🎉 All quality checks passed!$(RESET)"

# Pre-commit checks (run before committing)
pre-commit:
	@echo "$(BOLD)$(BLUE)🚀 Pre-commit Checks$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)1. Running tests...$(RESET)"
	@docker compose exec web bin/test --quiet || (echo "$(RED)❌ Tests failed$(RESET)" && exit 1)
	@echo "$(GREEN)✅ Tests passed$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)2. Checking Ruby code style...$(RESET)"
	@docker compose exec web bundle exec rubocop --format=quiet || (echo "$(RED)❌ RuboCop issues found$(RESET)" && exit 1)
	@echo "$(GREEN)✅ Ruby code style OK$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)3. Checking JavaScript code style...$(RESET)"
	@docker compose exec web yarn run lint:check --silent || (echo "$(RED)❌ JavaScript issues found$(RESET)" && exit 1)
	@echo "$(GREEN)✅ JavaScript OK$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)4. Security scan...$(RESET)"
	@docker compose exec web bundle exec brakeman --quiet || (echo "$(RED)❌ Security issues found$(RESET)" && exit 1)
	@echo "$(GREEN)✅ No security issues$(RESET)"
	@echo ""
	@echo "$(BOLD)$(GREEN)🎉 All pre-commit checks passed! Ready to commit.$(RESET)"

# Assets & Dependencies
# Compile assets for production
assets:
	@echo "$(BOLD)$(CYAN)🎨 Compiling assets for production...$(RESET)"
	docker compose exec web bin/rails assets:precompile RAILS_ENV=production
	@echo "$(GREEN)✓ Assets compiled$(RESET)"

# Compile assets for development
assets-dev:
	@echo "$(BOLD)$(CYAN)🎨 Compiling assets for development...$(RESET)"
	docker compose exec web yarn build
	@echo "$(GREEN)✓ Development assets compiled$(RESET)"

# Install Ruby gems
bundle:
	@echo "$(CYAN)Installing Ruby gems...$(RESET)"
	@if docker compose ps -q web >/dev/null 2>&1; then \
		docker compose exec web bundle install; \
	else \
		bundle install; \
	fi
	@echo "$(GREEN)✅ Ruby gems installed$(RESET)"

# Install JavaScript dependencies
yarn:
	@echo "$(CYAN)Installing JavaScript dependencies...$(RESET)"
	@if docker compose ps -q web >/dev/null 2>&1; then \
		docker compose exec web yarn install; \
	else \
		yarn install; \
	fi
	@echo "$(GREEN)✅ JavaScript dependencies installed$(RESET)"

# Install all dependencies
install:
	@echo "$(CYAN)Installing/updating all dependencies...$(RESET)"
	@$(MAKE) bundle --no-print-directory
	@$(MAKE) yarn --no-print-directory
	@echo "$(GREEN)✅ Dependencies updated$(RESET)"

# Update all dependencies
update:
	@echo "$(CYAN)Updating all dependencies...$(RESET)"
	docker compose exec web bundle update
	docker compose exec web yarn upgrade
	@echo "$(GREEN)✅ All dependencies updated$(RESET)"

# Configuration Management
# Initial setup for new developers
setup:
	@echo "$(BOLD)$(BLUE)⚙️  Setting up StreamSource development environment...$(RESET)"
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(GREEN)✓ Created .env file$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  .env file already exists$(RESET)"; \
	fi
	@echo "$(CYAN)Installing dependencies...$(RESET)"
	@$(MAKE) install --no-print-directory
	@echo "$(CYAN)Setting up database...$(RESET)"
	@docker compose up -d db
	@sleep 5
	@$(MAKE) migrate --no-print-directory
	@$(MAKE) seed --no-print-directory
	@echo ""
	@echo "$(BOLD)$(GREEN)✅ Setup complete! Next steps:$(RESET)"
	@echo "$(YELLOW)1.$(RESET) Edit .env with your configuration"
	@echo "$(YELLOW)2.$(RESET) Configure Redis and PostgreSQL URLs if needed"
	@echo "$(YELLOW)3.$(RESET) Run '$(CYAN)make dev$(RESET)' to start the application"
	@echo "$(YELLOW)4.$(RESET) Run '$(CYAN)make test$(RESET)' to verify everything works"
	@echo "$(YELLOW)5.$(RESET) Visit http://localhost:3000/admin to access the admin interface"

# Validate environment configuration
env-check:
	@echo "$(BOLD)$(CYAN)🔍 Checking environment configuration...$(RESET)"
	@if [ ! -f .env ]; then \
		echo "$(RED)❌ ERROR: .env file not found!$(RESET)"; \
		echo "Run '$(CYAN)make setup$(RESET)' to create one"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Required configuration:$(RESET)"
	@grep -q "SECRET_KEY_BASE=." .env && echo "$(GREEN)✓ SECRET_KEY_BASE$(RESET)" || echo "$(RED)✗ SECRET_KEY_BASE not set$(RESET)"
	@grep -q "DATABASE_URL=." .env && echo "$(GREEN)✓ DATABASE_URL$(RESET)" || echo "$(RED)✗ DATABASE_URL not set$(RESET)"
	@grep -q "REDIS_URL=." .env && echo "$(GREEN)✓ REDIS_URL$(RESET)" || echo "$(RED)✗ REDIS_URL not set$(RESET)"
	@echo "$(YELLOW)Optional configuration:$(RESET)"
	@grep -q "RAILS_HOSTNAME=." .env && echo "$(GREEN)✓ RAILS_HOSTNAME$(RESET)" || echo "$(YELLOW)⚠️  RAILS_HOSTNAME not set$(RESET)"
	@grep -q "FORCE_SSL=." .env && echo "$(GREEN)✓ FORCE_SSL$(RESET)" || echo "$(YELLOW)⚠️  FORCE_SSL not set$(RESET)"
	@echo "$(GREEN)✅ Configuration check complete$(RESET)"

# Show current configuration (sanitized)
config:
	@echo "$(BOLD)$(CYAN)⚙️  Current Configuration:$(RESET)"
	@if [ -f .env ]; then \
		echo "$(YELLOW)Environment variables:$(RESET)"; \
		grep -E "^[^#]" .env | sed 's/\(.*PASSWORD.*=\).*/\1[HIDDEN]/' | sed 's/\(.*SECRET.*=\).*/\1[HIDDEN]/' | sed 's/\(.*KEY.*=\).*/\1[HIDDEN]/' | sed 's/\(.*TOKEN.*=\).*/\1[HIDDEN]/'; \
		echo ""; \
		echo "$(YELLOW)Runtime versions:$(RESET)"; \
		docker compose exec web ruby --version 2>/dev/null || echo "$(RED)Ruby: Not available$(RESET)"; \
		docker compose exec web bin/rails --version 2>/dev/null || echo "$(RED)Rails: Not available$(RESET)"; \
		docker compose exec web node --version 2>/dev/null || echo "$(RED)Node.js: Not available$(RESET)"; \
	else \
		echo "$(RED)❌ No .env file found$(RESET)"; \
	fi

# Show all Rails routes
routes:
	@echo "$(CYAN)Rails Routes:$(RESET)"
	docker compose exec web bin/rails routes

# Backup configuration and database
backup:
	@echo "$(CYAN)Creating backup...$(RESET)"
	@mkdir -p backups
	@if [ -f .env ]; then cp .env backups/.env.backup.$$(date +%Y%m%d_%H%M%S); fi
	@docker compose exec db pg_dump -U streamsource streamsource_development > backups/db_backup_$$(date +%Y%m%d_%H%M%S).sql 2>/dev/null || true
	@echo "$(GREEN)✅ Backup created in backups/ directory$(RESET)"

# Security & Maintenance
# Security audit and secret scanning
security:
	@echo "$(BOLD)$(BLUE)🔒 Security Audit$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)1. Ruby Vulnerability Scan$(RESET)"
	@docker compose exec web bundle exec bundler-audit check --update || echo "$(RED)⚠️  Vulnerabilities found - review output above$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)2. Static Security Analysis$(RESET)"
	@docker compose exec web bundle exec brakeman -q --no-progress || echo "$(RED)⚠️  Security issues found - review output above$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)3. Secret Scanning$(RESET)"
	@echo "$(CYAN)Checking for exposed secrets...$(RESET)"
	@if grep -r "password\|secret\|key\|token" \
		--include="*.rb" \
		--include="*.js" \
		--include="*.yml" \
		--exclude-dir=vendor \
		--exclude-dir=node_modules \
		--exclude-dir=.git \
		--exclude-dir=backups \
		. | grep -v "ENV\|Rails.application.credentials\|process.env" | grep -v "# " | head -5; then \
		echo "$(RED)⚠️  WARNING: Possible exposed secrets found above!$(RESET)"; \
	else \
		echo "$(GREEN)✅ No exposed secrets found$(RESET)"; \
	fi
	@echo ""
	@echo "$(BOLD)$(YELLOW)4. File Permissions$(RESET)"
	@if [ -f .env ]; then \
		if [ "$$(stat -f %A .env 2>/dev/null || stat -c %a .env 2>/dev/null)" != "600" ]; then \
			echo "$(RED)⚠️  WARNING: .env file permissions are too open$(RESET)"; \
		else \
			echo "$(GREEN)✅ .env file permissions OK$(RESET)"; \
		fi; \
	fi

# Complete rebuild
rebuild:
	@echo "$(BOLD)$(BLUE)🔄 Complete Rebuild$(RESET)"
	@echo "$(YELLOW)Stopping services...$(RESET)"
	docker compose stop
	@echo "$(YELLOW)Removing containers and volumes...$(RESET)"
	docker compose down -v --remove-orphans
	@echo "$(YELLOW)Rebuilding images...$(RESET)"
	docker compose build --no-cache
	@echo "$(YELLOW)Starting services...$(RESET)"
	docker compose up -d
	@echo "$(GREEN)✅ Rebuild complete$(RESET)"
	docker compose logs -f

# Clean up everything (containers, volumes, logs)
clean:
	@echo "$(YELLOW)Cleaning up containers, volumes, and logs...$(RESET)"
	docker compose down -v --remove-orphans
	@rm -rf tmp/cache/* tmp/pids/* log/*.log 2>/dev/null || true
	@echo "$(GREEN)✅ Cleanup complete$(RESET)"

# Deep clean (including images and cache)
clean-all:
	@echo "$(BOLD)$(RED)🧹 Deep cleaning (this will remove all StreamSource Docker data)...$(RESET)"
	@read -p "Are you sure? This will remove all images and cached data. (y/N) " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo ""; \
		docker compose down -v --remove-orphans --rmi all; \
		docker system prune -f; \
		rm -rf tmp/ log/*.log node_modules/.cache 2>/dev/null || true; \
		echo "$(GREEN)✅ Deep clean complete$(RESET)"; \
	else \
		echo "$(YELLOW)Deep clean cancelled$(RESET)"; \
	fi

# Remove unused Docker resources
prune:
	@echo "$(YELLOW)Removing unused Docker resources...$(RESET)"
	docker system prune -f
	@echo "$(GREEN)✅ Docker resources pruned$(RESET)"

# Show version information
version:
	@echo "$(BOLD)$(CYAN)📋 StreamSource Version Information:$(RESET)"
	@echo "$(YELLOW)Ruby:$(RESET) $$(docker compose exec web ruby --version 2>/dev/null || echo 'Not available')"
	@echo "$(YELLOW)Rails:$(RESET) $$(docker compose exec web bin/rails --version 2>/dev/null || echo 'Not available')"
	@echo "$(YELLOW)Node.js:$(RESET) $$(docker compose exec web node --version 2>/dev/null || echo 'Not available')"
	@echo "$(YELLOW)Yarn:$(RESET) $$(docker compose exec web yarn --version 2>/dev/null || echo 'Not available')"
	@echo "$(YELLOW)PostgreSQL:$(RESET) $$(docker compose exec db psql --version 2>/dev/null || echo 'Not available')"
	@echo "$(YELLOW)Redis:$(RESET) $$(docker compose exec redis redis-server --version 2>/dev/null || echo 'Not available')"

# Troubleshooting
.PHONY: logs-all logs-file ps-all health doctor

# Show logs for all services
logs-all:
	@echo "$(CYAN)Following all service logs... (Ctrl+C to exit)$(RESET)"
	docker compose logs -f

# Show application log file
logs-file:
	@echo "$(CYAN)Application log file:$(RESET)"
	@if [ -f log/development.log ]; then \
		tail -f log/development.log; \
	elif [ -f log/production.log ]; then \
		tail -f log/production.log; \
	else \
		echo "$(YELLOW)⚠️  No log file found$(RESET)"; \
		echo "Check container logs with: $(CYAN)make logs$(RESET)"; \
	fi

# Show all containers (including stopped)
ps-all:
	@echo "$(CYAN)All containers (including stopped):$(RESET)"
	docker compose ps -a

# System health check
health:
	@echo "$(BOLD)$(BLUE)🏥 System Health Check$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)1. Container Status$(RESET)"
	@docker compose ps
	@echo ""
	@echo "$(BOLD)$(YELLOW)2. Rails Application$(RESET)"
	@if docker compose ps -q web >/dev/null 2>&1; then \
		docker compose exec web bin/rails runner "puts '$(GREEN)✅ Rails: OK$(RESET)'" 2>/dev/null || echo "$(RED)❌ Rails: ERROR$(RESET)"; \
	else \
		echo "$(RED)❌ Rails: Container not running$(RESET)"; \
	fi
	@echo ""
	@echo "$(BOLD)$(YELLOW)3. Database Connection$(RESET)"
	@docker compose exec web bin/rails runner "puts 'Database: ' + (ActiveRecord::Base.connection ? '$(GREEN)✅ Connected$(RESET)' : '$(RED)❌ Failed$(RESET)')" 2>/dev/null || echo "$(RED)❌ Database: Cannot connect$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)4. Redis Connection$(RESET)"
	@docker compose exec web bin/rails runner "puts 'Redis: ' + (Redis.new.ping == 'PONG' ? '$(GREEN)✅ Connected$(RESET)' : '$(RED)❌ Failed$(RESET)')" 2>/dev/null || echo "$(RED)❌ Redis: Cannot connect$(RESET)"
	@echo ""
	@echo "$(BOLD)$(YELLOW)5. Dependencies$(RESET)"
	@if [ -d vendor/bundle ] || [ -d node_modules ]; then echo "$(GREEN)✅ Dependencies: OK$(RESET)"; else echo "$(RED)❌ Dependencies: Missing - run 'make install'$(RESET)"; fi
	@echo ""
	@echo "$(BOLD)$(YELLOW)6. Configuration$(RESET)"
	@$(MAKE) env-check --no-print-directory 2>/dev/null || true

# Doctor - diagnose common issues
doctor:
	@echo "$(BOLD)$(BLUE)🩺 System Diagnostics$(RESET)"
	@echo ""
	@echo "$(BOLD)$(GREEN)1. Prerequisites$(RESET)"
	@docker --version >/dev/null 2>&1 && echo "$(GREEN)✅ Docker: $$(docker --version | cut -d' ' -f3 | cut -d',' -f1)$(RESET)" || echo "$(RED)❌ Docker: Not installed$(RESET)"
	@docker compose version >/dev/null 2>&1 && echo "$(GREEN)✅ Docker Compose: $$(docker compose version --short)$(RESET)" || echo "$(RED)❌ Docker Compose: Not installed$(RESET)"
	@echo ""
	@echo "$(BOLD)$(GREEN)2. Configuration$(RESET)"
	@$(MAKE) env-check --no-print-directory
	@echo ""
	@echo "$(BOLD)$(GREEN)3. Services$(RESET)"
	@$(MAKE) status --no-print-directory
	@echo ""
	@echo "$(BOLD)$(GREEN)4. Health Check$(RESET)"
	@$(MAKE) health --no-print-directory
	@echo ""
	@echo "$(BOLD)$(GREEN)5. Quick Test$(RESET)"
	@docker compose exec web bin/test --quiet >/dev/null 2>&1 && echo "$(GREEN)✅ Tests: Passing$(RESET)" || echo "$(RED)❌ Tests: Failing - run 'make test' for details$(RESET)"

# Additional Commands
.PHONY: exec run bundle-cmd yarn-cmd

# Execute command in web container
exec:
	@if [ -z "$(cmd)" ]; then \
		echo "$(YELLOW)Usage:$(RESET) make exec cmd='ls -la'"; \
		echo "$(YELLOW)Example:$(RESET) make exec cmd='bin/rails generate model Example'"; \
	else \
		docker compose exec web $(cmd); \
	fi

# Run command in new container
run:
	@if [ -z "$(cmd)" ]; then \
		echo "$(YELLOW)Usage:$(RESET) make run cmd='ruby --version'"; \
		echo "$(YELLOW)Example:$(RESET) make run cmd='bundle install'"; \
	else \
		docker compose run --rm web $(cmd); \
	fi

# Run bundle commands
bundle-cmd:
	@if [ -z "$(cmd)" ]; then \
		echo "$(YELLOW)Usage:$(RESET) make bundle-cmd cmd='add rspec-rails'"; \
		echo "$(YELLOW)Example:$(RESET) make bundle-cmd cmd='list'"; \
	else \
		if docker compose ps -q web >/dev/null 2>&1; then \
			docker compose exec web bundle $(cmd); \
		else \
			bundle $(cmd); \
		fi; \
	fi

# Run yarn commands
yarn-cmd:
	@if [ -z "$(cmd)" ]; then \
		echo "$(YELLOW)Usage:$(RESET) make yarn-cmd cmd='add lodash'"; \
		echo "$(YELLOW)Example:$(RESET) make yarn-cmd cmd='list --depth=0'"; \
	else \
		if docker compose ps -q web >/dev/null 2>&1; then \
			docker compose exec web yarn $(cmd); \
		else \
			yarn $(cmd); \
		fi; \
	fi

# Quick shortcuts for common commands
.PHONY: d u l r s c

d: dev
u: up
l: logs
r: restart
s: status
c: rails