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

The `caddy_data` volume is **external** — it must exist before first run:
```bash
docker volume create caddy_data
```

## Architecture

- **Caddy** (`lucaslorentz/caddy-docker-proxy`) — reverse proxy using Docker labels for routing config. Handles TLS automatically. Routes `/postgrest/*` → PostgREST, `/swagger/*` → Swagger UI.
- **PostgreSQL 1** (`postgrest-db`) — primary database on port 5432. Init scripts in `initdb/` run on first container creation.
- **PostgREST** — exposes the schema defined by `DB_SCHEMA` (default: `testschema`) in the `test` database as a REST API on internal port 3000.
- **Swagger UI** — serves OpenAPI docs sourced from PostgREST's auto-generated spec.
- **Frontend** (`html/`) — static vanilla JS app using Pure.css. Currently queries a legacy city endpoint (not wired into this compose stack).

## Key Configuration

All config lives in `.env`. Important variables:
- `DOMAIN` — hostname Caddy uses for TLS and routing (default: `localhost`)
- `DB_SCHEMA` — Postgres schema PostgREST exposes (default: `testschema`)
- `DB_ANON_ROLE` — Postgres role for unauthenticated API requests (default: `anon`)
- `POSTGREST_SUBPATH` — URL path prefix for PostgREST (default: `/postgrest`)
- Caddy uses the **staging** Let's Encrypt CA by default (`acme_ca` label). Remove that label to get production certs.

## Database Initialization

`initdb/init-db.sh` runs on first Postgres startup:
1. Creates the `test` database and `anon` role
2. Creates the schema and grants read-only access to `anon`
3. Creates a sample `test` table with indexes and a `view_of_test` view
4. Seeds 500 random rows
5. Adds OpenAPI documentation comments on schema/table/columns

To add new tables or seed data, add SQL files or modify `init-db.sh`. Changes only take effect on a fresh volume (run `docker-compose down -v` first).

## PostgREST API Patterns

Aggregates are enabled (`PGRST_DB_AGGREGATES_ENABLED=true`). Example queries:
- Filter: `?ts=gt.2023-01-01&ts=lt.2024-01-01`
- Select specific columns: `?select=id,name`
- Aggregates: `?select=val.count(),val.sum(),val.avg()`
- Pattern match: `?name=ilike.*search*`
