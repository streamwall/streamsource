# Project Overview

## Purpose
StreamSource manages streamers and their streaming sources with a RESTful API plus a real-time collaborative admin interface. It tracks streams, their status/lifecycle, and related metadata (locations, timestamps, accounts), and provides tooling for administrators to curate and monitor data.

## Architecture & Stack
- **Backend**: Rails 8 API + admin web UI, PostgreSQL, Redis.
- **Auth**: Devise + JWT for API; session-based login for admin UI.
- **Realtime**: ActionCable + Redis (presence + cell locks).
- **UI**: Hotwire (Turbo/Stimulus), Tailwind CSS, esbuild.
- **API tooling**: ActiveModelSerializers, Pagy, Rswag.
- **Ops**: Docker-only development, Rack::Attack rate limiting, Flipper feature flags.

## Core Data Model
- **User**: roles (`default`, `editor`, `admin`), service accounts (`is_service_account`), Devise auth. JWT payload includes `jti`, `exp`, `service_account`.
- **Stream**: `source`, `link`, `status` (`Live/Offline/Unknown`), `platform`, `orientation`, `kind`, `is_pinned`, `is_archived`, `started_at`, `ended_at`, `last_checked_at`, `last_live_at`, `city`, `state`, optional `location_id`, optional `streamer_id`. Belongs to `user`.
- **Streamer**: name + notes; has many `streamer_accounts` and `streams`.
- **StreamerAccount**: platform + username + profile URL; auto-generates profile URLs for some platforms.
- **Location**: normalized city/state/country, optional lat/long, `is_known_city` for validation.
- **Timestamp**: event time + title/description; many-to-many with streams via `TimestampStream`.
- **TimestampStream**: join table with `stream_timestamp_seconds` and `added_by_user_id`.
- **IgnoreList**: admin-managed list (types: `twitch_user`, `discord_user`, `url`, `domain`) with normalization.
- **JwtDenylist**: revocation table for JWT `jti`.

## Authentication & Authorization
- **API**: JWT required for all API endpoints except signup/login/logout. Tokens are issued in `POST /api/v1/login` and validated in `JwtAuthenticatable`.
- **Service accounts**: 30-day JWT expiry; created via rake tasks.
- **Roles**:
  - `default`: read-only streams.
  - `editor`: create/update streams.
  - `admin`: full access (including ignore lists and admin UI).
- **Authorization**:
  - **Pundit** used on API streams (`StreamPolicy`).
  - **Ignore lists** require admin via controller guard.
  - **Locations** currently authenticate but do not Pundit-authorize.
- **Maintenance mode**: Flipper flag returns 503 for API and renders an admin maintenance page.

## API Surface (from `config/routes.rb`)
Base path: `/api/v1`

**Auth**
- `POST /api/v1/signup` (Devise registrations)
- `POST /api/v1/login`
- `DELETE /api/v1/logout`

**Streams**
- `GET /api/v1/streams` (filters: `status`, `notStatus`, `user_id`, `is_pinned`, `sort`)
- `POST /api/v1/streams` (flat params; optional `location` hash or `location_id`)
- `GET /api/v1/streams/:id`
- `PATCH /api/v1/streams/:id`
- `DELETE /api/v1/streams/:id`
- `PUT /api/v1/streams/:id/pin`, `DELETE /api/v1/streams/:id/pin`
- `GET /api/v1/streams/:id/analytics` (feature-flagged)
- `POST /api/v1/streams/bulk_import` (feature-flagged)
- `GET /api/v1/streams/export` (feature-flagged)

**Locations**
- `GET /api/v1/locations` (search + pagination)
- `GET /api/v1/locations/all` (cached list)
- `GET /api/v1/locations/known_cities` (cached list)
- `GET /api/v1/locations/:id`
- `POST /api/v1/locations`
- `PATCH /api/v1/locations/:id`
- `DELETE /api/v1/locations/:id` (blocked when in use)

**Ignore Lists (admin only)**
- `GET /api/v1/ignore_lists` (filter/search + pagination)
- `GET /api/v1/ignore_lists/by_type`
- `GET /api/v1/ignore_lists/:id`
- `POST /api/v1/ignore_lists`
- `POST /api/v1/ignore_lists/bulk_create`
- `PATCH /api/v1/ignore_lists/:id`
- `DELETE /api/v1/ignore_lists/:id`
- `DELETE /api/v1/ignore_lists/bulk_delete`

**Health/ops**
- `GET /health`, `/health/live`, `/health/ready`
- `GET /metrics` (Prometheus)
- WebSocket: `/cable`
- Swagger UI: `/api-docs`, OpenAPI JSON: `/swagger`

## Admin Interface
HTML UI at `/admin` (redirects to `/admin/streams`) with session-based auth:
- CRUD for **streams**, **streamers**, **timestamps**, **locations**, **ignore lists**, **users**.
- Role gating: **admins + editors** can log in; admin-only actions enforced in some controllers.
- Feature flags UI at `/admin/flipper` (protected by `AdminFlipperAuth`).

## Real-time Collaboration
Admin streams list supports collaborative editing:
- **ActionCable channel**: `CollaborativeStreamsChannel`.
- **Cell locking**: Redis keys with 30s TTL, per-user lock ownership.
- **Presence**: Redis set + per-user JSON blobs (300s TTL).
- **Events**: `cell_locked`, `cell_unlocked`, `cell_updated`, `active_users_list`, `user_joined`, `user_left`, `stream_updated`.
- **Turbo Streams**: `Stream` model broadcasts prepend/replace/remove for list updates.

## Feature Flags (Flipper)
Defined in `config/application_constants.rb`:
- `stream_analytics`, `stream_bulk_import`, `stream_export`, `stream_tags`
- `advanced_search`, `maintenance_mode`, `location_validation`

## Notable Implementation Details
- **Streams** auto-archive when offline/unknown for 30+ minutes.
- **Locations** can be auto-created from `city/state` unless `location_validation` is enabled (then only known cities are allowed).
- **Rate limiting** via Rack::Attack (global + login/signup throttles).
- **Pagination**: custom pagination helper for streams/ignore lists; Pagy for locations (meta payloads differ).

## Porting Notes / Known Mismatches
- **Docs drift**: `docs/API.md` and `swagger/v1/swagger.yaml` still document `streamers` and `timestamps` API endpoints that are **not currently routed** under `/api/v1`. These are **admin-only** today.
- **Auth payloads**: API login expects `{ "user": { "email": "...", "password": "..." } }`. Signup expects a `user` object and **does not** return a JWT.
- **Stream payloads**: API expects **flat** stream attributes (not nested under `stream`), plus optional `location` hash.
- **Routes**: login/signup paths are `/api/v1/login` and `/api/v1/signup` (not `/api/v1/users/login`).

For a Django/DRF port, plan equivalents for Devise+JWT, Pundit permissions, Flipper flags, ActionCable realtime collaboration (Django Channels), and Rack::Attack throttling.
