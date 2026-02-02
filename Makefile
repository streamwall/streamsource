# StreamSource
# Usage: make [command]

.PHONY: help up down stop restart shell test migrate seed setup reset logs lint rebuild browse

STREAMSOURCE_ENV ?= dev
APP_URL ?= http://localhost:3001/admin

ifeq ($(STREAMSOURCE_ENV),prod)
COMPOSE_FILES := -f docker-compose.yml -f docker-compose.prod.yml
UP_TARGETS := web
else
COMPOSE_FILES :=
UP_TARGETS :=
endif

COMPOSE := docker compose $(COMPOSE_FILES)

help:
	@echo "Commands:"
	@echo "  up       - Start services (STREAMSOURCE_ENV=prod for production)"
	@echo "  down     - Stop services"
	@echo "  stop     - Stop services without removing containers"
	@echo "  restart  - Restart services without removing containers"
	@echo "  browse   - Open the app in your browser (APP_URL=$(APP_URL))"
	@echo "  shell    - Rails console"
	@echo "  test     - Run tests"
	@echo "  lint     - Run lint checks (RuboCop, ESLint)"
	@echo "  rebuild  - Clean and rebuild containers"
	@echo "  migrate  - Run migrations"
	@echo "  seed     - Seed the database"
	@echo "  setup    - Create, migrate, and seed the database"
	@echo "  reset    - Drop, create, migrate, and seed the database"
	@echo "  logs     - View logs"

up:
	$(COMPOSE) up -d $(UP_TARGETS)

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

restart:
	$(COMPOSE) restart

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
	$(COMPOSE) exec web bin/rails console

test:
	$(COMPOSE) exec web bin/test

lint:
	$(COMPOSE) exec web bundle exec rubocop
	$(COMPOSE) exec web yarn lint

rebuild:
	$(COMPOSE) down --remove-orphans
	$(COMPOSE) build --no-cache
	$(COMPOSE) up -d $(UP_TARGETS)

migrate:
	$(COMPOSE) exec web bin/rails db:migrate

seed:
	$(COMPOSE) exec web bin/rails db:seed

setup:
	$(COMPOSE) exec web bin/rails db:setup

reset:
	$(COMPOSE) exec web bin/rails db:reset

logs:
	$(COMPOSE) logs -f
