# AGENTS.md

Monorepo root at `/holdly`: `backend/` (Spring Boot).

## Commands

Run Maven from `backend/`. There is **no Maven wrapper** (`mvnw`) — use system `mvn`.

- Build/compile: `mvn compile` (also generates MapStruct mappers)
- Test: `mvn test` (no tests exist yet)
- Run: `mvn spring-boot:run` (server on port 8080)

No separate lint/format step is configured (no checkstyle/spotless). Compilation is the verification gate.

## Docker

- `backend/Dockerfile` is a multi-stage build: Maven builder (`maven:3.9.16-eclipse-temurin-21-alpine`) → runtime `eclipse-temurin:21-jre-alpine` running as non-root user `holdly`. It copies the jar from `mvn package` output.
- Built/run via the root `docker-compose.yml` `full` profile: `docker compose --profile full up -d --build`. Local infra (PostgreSQL/Redis only) is `docker compose up -d`.
- `backend/.dockerignore` excludes `target/`, `.agents/`, `skills-lock.json` from the build context.

## Stack facts

- Spring Boot 3.5.16, Java 21, Maven, packaged under `com.holdly`. Follow the `com.holdly.<feature>` package convention.
- Lombok + MapStruct (1.6.3) with `lombok-mapstruct-binding` are wired via `maven-compiler-plugin` annotationProcessorPaths in `pom.xml`. MapStruct mapper interfaces compile to implementations automatically — do not hand-write them.
- PostgreSQL via standard DataSource auto-configuration: `application.yml` resolves `spring.datasource.*` from `POSTGRES_PORT`/`POSTGRES_DB`/`POSTGRES_USER`/`POSTGRES_PASSWORD` env vars (host-run default `localhost:${POSTGRES_PORT}`; Compose overrides the URL with the `postgres` service name via injected `SPRING_DATASOURCE_URL`). Hibernate runs `ddl-auto: validate` and `open-in-view: false`; no migration tooling — schema changes are manual SQL for now.
- **Local dev `.env` loading**: `dotenv-java` (cdimascio) loads `backend/.env` at startup via `DotenvEnvironmentPostProcessor`. The backend owns its `.env` separately from the root `.env` (used by Docker Compose). Server port is configurable via `SERVER_PORT`.
- Health: Spring Boot Actuator only — `GET /actuator/health` (only exposed endpoint), consumed by the Dockerfile `HEALTHCHECK`. No custom health controller; don't add one.
- springdoc-openapi is present: API docs at `/swagger-ui.html`, spec at `/v3/api-docs`.
- Endpoints are prefixed `/api`. Keep this convention.

## Gotchas

- `target/` (Maven build output) is **not** in `.gitignore` — don't commit it. Git history currently has `target/` clean; be careful with `git add -A`.
- `.env*` files are gitignored. Backend uses `dotenv-java` to load `backend/.env` at startup; root `.env` is for Docker Compose only.