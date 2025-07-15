# StreamSource
# Usage: make [command]

.PHONY: help up down shell test migrate logs

help:
	@echo "Commands:"
	@echo "  up       - Start services"
	@echo "  down     - Stop services"
	@echo "  shell    - Rails console"
	@echo "  test     - Run tests"
	@echo "  migrate  - Run migrations"
	@echo "  logs     - View logs"

up:
	docker compose up -d

down:
	docker compose down

shell:
	docker compose exec web bin/rails console

test:
	docker compose exec web bin/test

migrate:
	docker compose exec web bin/rails db:migrate

logs:
	docker compose logs -f