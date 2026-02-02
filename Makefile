# StreamSource
# Usage: make [command]

.PHONY: help up down shell test migrate seed setup reset logs

STREAMSOURCE_ENV ?= dev

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
	@echo "  shell    - Rails console"
	@echo "  test     - Run tests"
	@echo "  migrate  - Run migrations"
	@echo "  seed     - Seed the database"
	@echo "  setup    - Create, migrate, and seed the database"
	@echo "  reset    - Drop, create, migrate, and seed the database"
	@echo "  logs     - View logs"

up:
	$(COMPOSE) up -d $(UP_TARGETS)

down:
	$(COMPOSE) down

shell:
	$(COMPOSE) exec web bin/rails console

test:
	$(COMPOSE) exec web bin/test

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
