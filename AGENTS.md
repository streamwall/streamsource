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
- Prod/dev switch: `STREAMSOURCE_ENV=prod make up` uses `docker-compose.prod.yml` plus base compose.
- Rails console: `make shell` or `docker compose exec web bin/rails console`.
- Migrations: `make migrate`.
- Tests: `make test` or `docker compose exec web bin/test [path]`.
- Lint: `make lint` (runs RuboCop + ESLint).
- Rebuild: `make rebuild` (clean + rebuild containers).
- Security: `docker compose exec web bundle exec brakeman -q -w2`, `docker compose exec web bundle exec bundler-audit check --update`.
- JS/CSS build: `docker compose exec web yarn build` and `docker compose exec web yarn build:css`.

## Coding Style & Naming Conventions
- Indentation: 2 spaces (EditorConfig).
- Ruby: RuboCop (Rails/RSpec), line length 120, prefer double quotes.
- JavaScript: ESLint Standard; single quotes, no semicolons, 2-space indent.
- Naming: specs use `*_spec.rb`; factories live in `spec/factories/`.
- Gemfile entries must be alphabetized within each group (Bundler/OrderedGems).

## Testing Guidelines
- Framework: RSpec with FactoryBot; avoid fixtures.
- Run a single spec: `docker compose exec web bin/test spec/models/user_spec.rb`.
- Coverage target is >90% (see `docs/LINTING.md`); add edge-case coverage for controllers and services.
- CI uses the `RspecJunitFormatter`; keep `rspec_junit_formatter` in the test group.

## Test Helpers & Auth
- Prefer real login helpers over controller stubbing; avoid `allow_any_instance_of` in request specs.
- `sign_in_admin` posts top-level `email`/`password` params (admin sessions controller does not use nested params).

## CI/Workflow Notes
- GitHub Actions versions are bumped in both `.github/workflows/pr-validation.yml` and `.github/workflows/deploy.yml`.
- JavaScript linting runs via `yarn lint` (alias of ESLint).

## Commit & Pull Request Guidelines
- Commit messages are short, imperative, and lowercase (e.g., “simplify makefile”).
- Branch naming: `feature/...`, `fix/...`, `docs/...`.
- PRs should include a brief summary, tests run, and doc updates. If API changes, update `docs/API.md` and `swagger/v1/swagger.yaml`.
