# compose-postgrest

[Postgres](https://www.postgresql.org/), [PostgREST](https://github.com/begriffs/postgrest), and [Swagger UI](https://github.com/swagger-api/swagger-ui) conveniently wrapped up with docker-compose. [Caddy](https://caddyserver.com/) serves as a reverse proxy with automatic HTTPS.

Place SQL into the `initdb` folder, get REST!

Contains a simple front-end demo application.

## Architecture

![Deployment Diagram](diagrams/deployment-diagram.png)

### Compose File Structure

- `docker-compose.yml` — core services: PostgreSQL, PostgREST, Swagger UI
- `docker-compose.override.yml` — Caddy reverse proxy (automatically loaded by `docker-compose up`)
- `Caddyfile` — static reverse proxy routing configuration

## Usage

### Start the containers

`docker-compose up -d`

### Tearing down the containers

`docker-compose down --remove-orphans -v`

### Running without Caddy

`docker-compose -f docker-compose.yml up -d`

## Configuration

All configuration is in `.env`:

| Variable | Default | Purpose |
|----------|---------|---------|
| `DOMAIN` | `localhost` | Hostname for Caddy TLS |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | `postgres` / `postgres` | PostgreSQL superuser |
| `POSTGREST_DB` | `postgrest` | Database for PostgREST |
| `POSTGREST_USER` / `POSTGREST_PASSWORD` | `postgrest_user` / `postgrest_pass` | Unprivileged PostgREST database user |
| `DB_SCHEMA` | `testschema` | Schema exposed as API |
| `DB_ANON_ROLE` | `anon` | Anonymous API access role |
| `POSTGREST_SUBPATH` | `/postgrest` | URL path prefix |

## Demo Application

Located at <https://localhost/>

### SwaggerUI API docs

- <https://localhost/swagger/>

### Postgrest

- [Official API docs](https://docs.postgrest.org/en/v12/references/api.html)

#### Examples

- PostgREST API endpoint: <https://localhost/postgrest/>

Try things like:

- <https://localhost/postgrest/test>
- <https://localhost/postgrest/test?ts=gt.2023-01-01&ts=lt.2024-01-01>
- <https://localhost/postgrest/test?select=val.count(),val.sum(),val.avg()>
- <https://localhost/postgrest/view_of_test>
