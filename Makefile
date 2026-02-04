# StreamSource
# Usage: make [command]

.PHONY: help up down stop restart shell test migrate seed setup reset logs lint lint-fix lint-ruby lint-js security quality pre-commit pre-commit-install rebuild clean browse rake yarn

STREAMSOURCE_ENV ?= dev
APP_URL ?= http://localhost:3001/admin

ifeq ($(STREAMSOURCE_ENV),prod)
COMPOSE_FILES := -f docker-compose.yml -f docker-compose.prod.yml
UP_TARGETS := web
else
COMPOSE_FILES :=
UP_TARGETS := web js css
endif

COMPOSE := docker compose $(COMPOSE_FILES)
COMPOSE_UP := $(COMPOSE)
COMPOSE_EXEC_FLAGS ?=
COMPOSE_EXEC := $(COMPOSE) exec $(COMPOSE_EXEC_FLAGS)

ifeq ($(STREAMSOURCE_ENV),prod)
RESTART_CMD = $(COMPOSE) restart
else
RESTART_CMD = $(COMPOSE_UP) up -d --force-recreate $(UP_TARGETS)
endif

help:
	@echo "Commands:"
	@echo "  up       - Start services (STREAMSOURCE_ENV=prod for production)"
	@echo "  down     - Stop services"
	@echo "  stop     - Stop services without removing containers"
	@echo "  restart  - Restart services without removing containers"
	@echo "  browse   - Open the app in your browser (APP_URL=$(APP_URL))"
	@echo "  shell    - Rails console"
	@echo "  rake     - Run a rake task (make rake streams:import_streamwall)"
	@echo "  test     - Run tests"
	@echo "  lint     - Run lint checks (RuboCop, ESLint)"
	@echo "  lint-fix - Auto-fix lint issues (RuboCop, ESLint)"
	@echo "  lint-ruby - Run RuboCop only"
	@echo "  lint-js  - Run ESLint only"
	@echo "  security - Run security checks (Brakeman, bundler-audit)"
	@echo "  quality  - Run lint + tests"
	@echo "  pre-commit - Run CI checks before commit/push"
	@echo "  pre-commit-install - Install pre-commit hooks (commit + pre-push)"
	@echo "  yarn     - Build JS/CSS assets"
	@echo "  rebuild  - Clean and rebuild containers"
	@echo "  clean    - Remove containers, volumes, images, and build cache"
	@echo "  migrate  - Run migrations"
	@echo "  seed     - Seed the database"
	@echo "  setup    - Create, migrate, and seed the database"
	@echo "  reset    - Drop, create, migrate, and seed the database"
	@echo "  logs     - View logs"

up:
	$(COMPOSE_UP) up -d $(UP_TARGETS)

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

restart:
	$(RESTART_CMD)

browse:
	@url="$(APP_URL)"; \
	if [ "$(STREAMSOURCE_ENV)" != "prod" ]; then \
	  echo "Admin login (dev): admin@example.com / Password123!"; \
	  echo "Alternate admin: admin2@example.com / Password123!"; \
	  echo "Run \`make seed\` if these users are missing."; \
	fi; \
	if command -v open >/dev/null 2>&1; then \
	  open "$$url"; \
	elif command -v xdg-open >/dev/null 2>&1; then \
	  xdg-open "$$url"; \
	else \
	  echo "Open $$url in your browser."; \
	fi

shell:
	$(COMPOSE_EXEC) web bin/rails console

rake:
	@task="$(filter-out $@,$(MAKECMDGOALS))"; \
	if [ -z "$$task" ]; then \
	  echo "Usage: make rake <task> [ARGS=...]"; \
	  echo "Example: make rake streams:import_streamwall"; \
	  exit 1; \
	fi; \
	$(COMPOSE_EXEC) web bundle exec rake $$task

%:
	@:

test:
	$(COMPOSE_EXEC) web bin/test

lint: lint-ruby lint-js

lint-ruby:
	$(COMPOSE_EXEC) web bundle exec rubocop

lint-js:
	$(COMPOSE_EXEC) web yarn lint

lint-fix:
	$(COMPOSE_EXEC) web bundle exec rubocop -A
	$(COMPOSE_EXEC) web yarn lint:js:fix

security:
	$(COMPOSE_EXEC) web bundle exec brakeman -q -w2
	$(COMPOSE_EXEC) web bundle exec bundler-audit check --update

quality:
	$(MAKE) lint
	$(MAKE) test

pre-commit:
	$(MAKE) lint
	$(MAKE) security
	$(MAKE) test

pre-commit-install:
	@command -v pre-commit >/dev/null 2>&1 || { \
	  echo "pre-commit is not installed. Install it first: https://pre-commit.com/#install"; \
	  exit 1; \
	}
	pre-commit install
	pre-commit install --hook-type pre-push

yarn:
	$(COMPOSE_EXEC) web yarn build
	$(COMPOSE_EXEC) web yarn build:css

rebuild:
	$(COMPOSE) down --remove-orphans
	$(COMPOSE) build
	$(COMPOSE_UP) up -d $(UP_TARGETS)

clean:
	$(COMPOSE) down --remove-orphans --volumes --rmi local
	docker builder prune -f

migrate:
	$(COMPOSE_EXEC) web bin/rails db:migrate

seed:
	$(COMPOSE_EXEC) web bin/rails db:seed

setup:
	$(COMPOSE_EXEC) web bin/rails db:setup

reset:
	$(COMPOSE_EXEC) web bin/rails db:reset

logs:
	$(COMPOSE) logs -f
