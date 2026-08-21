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

- Spring Boot 3.5.16, Java 21, Maven, packaged under `com.holdly` (e.g. `com.holdly.health`). Follow the `com.holdly.<feature>` package convention.
- Lombok + MapStruct (1.6.3) with `lombok-mapstruct-binding` are wired via `maven-compiler-plugin` annotationProcessorPaths in `pom.xml`. MapStruct mapper interfaces compile to implementations automatically — do not hand-write them.
- `spring-boot-starter-data-jpa` is a dependency, but `application.yml` **excludes** `DataSourceAutoConfiguration` and `HibernateJpaAutoConfiguration`. The app runs without a database and has no DB config yet. Re-enable these (and add a datasource) before relying on JPA at runtime.
- springdoc-openapi is present: API docs at `/swagger-ui.html`, spec at `/v3/api-docs`.
- Endpoints are prefixed `/api` (see `com.holdly.health.HealthController` → `/api/health`). Keep this convention.

## Gotchas

- `target/` (Maven build output) is **not** in `.gitignore` — don't commit it. Git history currently has `target/` clean; be careful with `git add -A`.
- `.env*` files are gitignored, but there is no env loading in the app yet (no `.env` support, no config server).