# AGENTS.md

Monorepo for Holdly, a multi-tenant reservable-spaces platform.

## Layout

- `backend/` — Spring Boot 3.5.16 / Java 21 API. Read `backend/AGENTS.md` before working here.
- `frontend/` — empty placeholder; no frontend stack is scaffolded yet.
- `docker-compose.yml` — infra + containerized stack selected via Compose profiles.
- `.agents/` — agent skills (e.g. `java-springboot`, `multi-stage-dockerfile`).

## Docker / Compose

Run `docker compose` from the repo root.

- `docker compose up -d` — PostgreSQL + Redis only (for local dev; host ports from `POSTGRES_PORT`/`REDIS_PORT` in `.env`).
- `docker compose --profile full up -d --build` — full stack: adds `backend`, built from the multi-stage `backend/Dockerfile`.
- Data persists in named volumes `holdly_postgres_data` and `holdly_redis_data`.
- Credentials live only in the root `.env` (copy `.env.example` after cloning; it is gitignored). Compose has no inline fallbacks — without `.env`, `docker compose` fails.
- Redis requires auth (`--requirepass` from `REDIS_PASSWORD`); Postgres credentials are `POSTGRES_DB`/`POSTGRES_USER`/`POSTGRES_PASSWORD`.
- The backend container runs as non-root user and health-checks `/actuator/health`.
- Compose injects `SPRING_DATASOURCE_*`/`SPRING_DATA_REDIS_*` env vars; `SPRING_DATASOURCE_URL` overrides the backend's `localhost` JDBC URL inside the Compose network (service name `postgres`). Redis vars are inert (no Redis starter yet).

## Verify infra connectivity (ping/pong)

With `docker compose up -d` running, from the repo root:

- Redis: `docker compose exec -T redis sh -c 'redis-cli --no-auth-warning -a "$REDIS_PASSWORD" ping'` → expects `PONG`.
- PostgreSQL: `docker compose exec -T postgres pg_isready -U holdly_app -d holdly` → expects `accepting connections`; round-trip with `docker compose exec -T postgres psql -U holdly_app -d holdly -c "SELECT 'pong' AS ping;"` → returns `pong`.
- Host ports for native apps: postgres on `localhost:${POSTGRES_PORT}`, redis on `localhost:${REDIS_PORT}` (probe with `exec 3<>/dev/tcp/localhost/5432`).

## Backend commands

Run Maven from `backend/` — there is **no Maven wrapper**, use system `mvn`.

- Compile/verify: `mvn compile` (also generates MapStruct mappers). No lint/format step is configured; compilation is the gate.
- Build the container image: `docker compose --profile full build` (or `docker build ./backend`).

## Gotchas

- `target/` (Maven output) is **not** gitignored — never `git add -A` from the root; stage files explicitly.
- `.env*` is gitignored (except `.env.example`), and the app has no env-loading support yet — configuration comes from Compose env vars and `application.yml`.
- Postgres credentials only apply on first volume init (`initdb`). Changing them later requires `docker compose down -v` to recreate the volume.