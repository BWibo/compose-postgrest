# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Configurable PostgREST settings: `PGRST_DB_MAX_ROWS`, `PGRST_DB_POOL`, `PGRST_DB_POOL_ACQUISITION_TIMEOUT` exposed as environment variables.
- Production-hardening recommendations as commented settings in `.env` (error verbosity, OpenAPI mode, pool lifecycle, logging, admin health endpoint).
- Comprehensive usage commands, endpoint reference, and query examples in README.
- Database Roles section in README explaining PostgREST's three-role security model and request flow.
- Detailed documentation in `init-db.sh` explaining role hierarchy, schema permissions, and marking demo data as optional.

### Changed

- Renamed PostgREST database role from `postgrest_user` to `authenticator` following PostgREST best practices.
- Added `NOINHERIT NOCREATEDB NOCREATEROLE NOSUPERUSER` attributes to the authenticator role for tighter security.
- Updated documentation in CLAUDE.md with new PostgREST settings table.
- Switched PostgreSQL data storage to a named external Docker volume (`postgrest_pgdata`) for explicit data lifecycle management.
