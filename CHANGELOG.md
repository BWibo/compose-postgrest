# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Configurable PostgREST settings: `PGRST_DB_MAX_ROWS`, `PGRST_DB_POOL`, `PGRST_DB_POOL_ACQUISITION_TIMEOUT` exposed as environment variables.
- Production-hardening recommendations as commented settings in `.env` (error verbosity, OpenAPI mode, pool lifecycle, logging, admin health endpoint).
- Comprehensive usage commands, endpoint reference, and query examples in README.

### Changed

- Updated documentation in CLAUDE.md with new PostgREST settings table.
- Switched PostgreSQL data storage to a named external Docker volume (`postgrest_pgdata`) for explicit data lifecycle management.
