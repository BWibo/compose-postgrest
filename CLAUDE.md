# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker Compose stack that wires together PostgreSQL, PostgREST (auto-generated REST API from a Postgres schema), Swagger UI, and a Caddy reverse proxy with automatic HTTPS. A simple vanilla JS frontend demo is included.

## Running

```bash
# Start all services (Postgres, PostgREST, Swagger UI, Caddy)
docker-compose up -d

# Tear down (removes volumes too — full reset)
docker-compose down --remove-orphans -v
```

Note: `docker-compose up` automatically merges `docker-compose.yml` + `docker-compose.override.yml`. To run without Caddy: `docker-compose -f docker-compose.yml up -d`.

## Architecture

- **Caddy** (`caddy:2-alpine`, in `docker-compose.override.yml`) — reverse proxy configured via a static `Caddyfile`. Routes `/postgrest/*` → PostgREST, `/swagger/*` → Swagger UI. Auto-generates internal TLS cert for `localhost`.
- **PostgreSQL 18** (`postgrest-db`) — primary database on port 5432. Init scripts in `initdb/` run on first container creation only (requires volume reset to re-run).
- **PostgREST** — connects as `authenticator` (LOGIN, NOINHERIT) and switches to `anon` for unauthenticated requests. Exposes the schema defined by `DB_SCHEMA` (default: `testschema`) in the `postgrest` database as a REST API.
- **Swagger UI** — serves OpenAPI docs sourced from PostgREST's auto-generated spec.
- **Frontend** (`html/`) — static vanilla JS app using Pure.css. Currently queries a legacy city endpoint (not wired into this compose stack).

## Key Configuration

All config lives in `.env`. Important variables:

| Variable | Default | Purpose |
|----------|---------|---------|
| `DOMAIN` | `localhost` | Hostname for Caddy TLS and Swagger API URL |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | `postgres` / `postgres` | PostgreSQL superuser (used by init scripts only) |
| `POSTGREST_DB` | `postgrest` | Database created for PostgREST |
| `POSTGREST_USER` / `POSTGREST_PASSWORD` | `authenticator` / `postgrest_pass` | LOGIN NOINHERIT role PostgREST connects as (switches to `anon` for unauthenticated requests) |
| `DB_SCHEMA` | `testschema` | Schema PostgREST exposes as API |
| `DB_ANON_ROLE` | `anon` | NOLOGIN role for unauthenticated API requests |
| `POSTGREST_SUBPATH` | `/postgrest` | URL path prefix for PostgREST |
| `PGRST_DB_MAX_ROWS` | `1000` | Maximum rows returned per request |
| `PGRST_DB_POOL` | `2` | Database connection pool size (increase for production) |
| `PGRST_DB_POOL_ACQUISITION_TIMEOUT` | `10` | Seconds to wait for a free pool connection |

Additional production settings are documented as comments in `.env` (error verbosity, OpenAPI mode, pool lifecycle, logging, admin server).

## Database Initialization

`initdb/init-db.sh` runs on first Postgres startup:
1. Creates `${POSTGREST_DB}` database
2. Creates `${DB_ANON_ROLE}` as a NOLOGIN role and `${POSTGREST_USER}` (`authenticator`) as a LOGIN NOINHERIT role with password
3. Grants `${DB_ANON_ROLE}` to `${POSTGREST_USER}` (required for PostgREST role switching via `SET ROLE`)
4. Creates the schema and grants read-only access to `${DB_ANON_ROLE}`
5. Creates a sample `test` table with indexes and a `view_of_test` view
6. Seeds 500 random rows and adds OpenAPI documentation comments

Changes to init scripts only take effect on a fresh volume (`docker-compose down -v` first).

## Compose File Structure

- `docker-compose.yml` — core services: postgrest-db, postgrest, swagger-ui, network
- `docker-compose.override.yml` — Caddy reverse proxy (automatically loaded by `docker-compose up`)
- `Caddyfile` — static reverse proxy routing (mounted into Caddy container)

## PostgREST API Patterns

Aggregates are enabled (`PGRST_DB_AGGREGATES_ENABLED=true`). Example queries:
- Filter: `?ts=gt.2023-01-01&ts=lt.2024-01-01`
- Select specific columns: `?select=id,name`
- Aggregates: `?select=val.count(),val.sum(),val.avg()`
- Pattern match: `?name=ilike.*search*`
