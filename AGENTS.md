# Repository Guidelines

## Project Structure & Module Organization
- `app/`: Rails application code (controllers, models, views, policies).
- `app/javascript/`: Stimulus controllers and JS entrypoints; compiled into `app/assets/builds/`.
- `app/assets/`: Tailwind entry CSS and built assets.
- `config/`: Rails configuration (routes, initializers, environments).
- `db/`: migrations, schema, and seeds.
- `spec/`: RSpec tests, factories, and support helpers.
- `docs/` + `swagger/`: API documentation and Swagger spec.
- `deploy/`: deployment scripts and infrastructure configs.

## Build, Test, and Development Commands
This repo is Docker-only; do not use system Ruby/Bundler.
- Start/stop: `make up`, `make down`, logs with `make logs`.
- Rails console: `make shell` or `docker compose exec web bin/rails console`.
- Migrations: `make migrate`.
- Tests: `make test` or `docker compose exec web bin/test [path]`.
- Lint/security: `docker compose exec web bundle exec rubocop`, `docker compose exec web bundle exec brakeman -q -w2`.
- JS/CSS build: `docker compose exec web yarn build` and `docker compose exec web yarn build:css`.

## Coding Style & Naming Conventions
- Indentation: 2 spaces (EditorConfig).
- Ruby: RuboCop (Rails/RSpec), line length 120, prefer double quotes.
- JavaScript: ESLint Standard; single quotes, no semicolons, 2-space indent.
- Naming: specs use `*_spec.rb`; factories live in `spec/factories/`.

## Testing Guidelines
- Framework: RSpec with FactoryBot; avoid fixtures.
- Run a single spec: `docker compose exec web bin/test spec/models/user_spec.rb`.
- Coverage target is >90% (see `docs/LINTING.md`); add edge-case coverage for controllers and services.

## Commit & Pull Request Guidelines
- Commit messages are short, imperative, and lowercase (e.g., “simplify makefile”).
- Branch naming: `feature/...`, `fix/...`, `docs/...`.
- PRs should include a brief summary, tests run, and doc updates. If API changes, update `docs/API.md` and `swagger/v1/swagger.yaml`.
