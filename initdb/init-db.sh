#!/bin/bash
#
# PostgREST database initialization script
# =========================================
# Runs once on first PostgreSQL container startup (docker-entrypoint-initdb.d).
# To re-run, remove the data volume: docker compose down -v && docker compose up -d
#
# This script does two things:
#   1. Sets up the PostgREST database, roles, and schema (required).
#   2. Creates a sample "test" table with seed data for demo purposes (optional).
#
# All names are driven by environment variables defined in .env.

# ---------------------------------------------------------------------------
# Step 1 — Database and roles
# ---------------------------------------------------------------------------
# Creates the PostgREST database and the role hierarchy:
#   - anon (NOLOGIN)        : anonymous request role, used by PostgREST for
#                              unauthenticated API access. Has no login capability.
#   - authenticator (LOGIN, NOINHERIT) : the role PostgREST connects as. NOINHERIT
#                              means it has zero privileges on its own — it can only
#                              act via SET ROLE to one of its granted roles (e.g. anon).
#   - anon is granted to authenticator so PostgREST can SET ROLE to it.
#
# See https://docs.postgrest.org/en/stable/tutorials/tut0.html for details.
psql -U ${POSTGRES_USER} <<-END
    CREATE DATABASE ${POSTGREST_DB};
    CREATE ROLE ${DB_ANON_ROLE} NOLOGIN;
    CREATE ROLE ${POSTGREST_USER} LOGIN NOINHERIT NOCREATEDB NOCREATEROLE NOSUPERUSER PASSWORD '${POSTGREST_PASSWORD}';
    GRANT ${DB_ANON_ROLE} TO ${POSTGREST_USER};
END

# ---------------------------------------------------------------------------
# Step 2 — Schema and permissions
# ---------------------------------------------------------------------------
# Creates the schema that PostgREST will expose as a REST API and grants
# read-only access to the anonymous role. ALTER DEFAULT PRIVILEGES ensures
# any tables created later in this schema are also readable by anon.
psql -U ${POSTGRES_USER} -d ${POSTGREST_DB} <<-END
    CREATE SCHEMA ${DB_SCHEMA};
    GRANT USAGE ON SCHEMA ${DB_SCHEMA} TO ${DB_ANON_ROLE};
    ALTER DEFAULT PRIVILEGES IN SCHEMA ${DB_SCHEMA} GRANT SELECT ON TABLES TO ${DB_ANON_ROLE};
    GRANT SELECT ON ALL SEQUENCES IN SCHEMA ${DB_SCHEMA} TO ${DB_ANON_ROLE};
    GRANT SELECT ON ALL TABLES IN SCHEMA ${DB_SCHEMA} TO ${DB_ANON_ROLE};
END

# ===========================================================================
# Sample / demo data (everything below is optional)
# ===========================================================================
# The following steps create a test table, a view, indexes, and seed data
# to demonstrate PostgREST functionality out of the box. You can safely
# remove or replace everything below this line with your own schema.
# ===========================================================================

# ---------------------------------------------------------------------------
# Step 3 — Demo table, view, indexes, and seed data
# ---------------------------------------------------------------------------
psql -U ${POSTGRES_USER} -d ${POSTGREST_DB} <<-END
BEGIN;
    -- Demo table with a mix of column types to exercise PostgREST features
    -- (filtering, ordering, aggregates, pattern matching).
    CREATE TABLE ${DB_SCHEMA}.test (
        id SERIAL PRIMARY KEY,
        name TEXT,
        type TEXT,
        ts DATE,
        val NUMERIC
    );

    CREATE INDEX test_eui on ${DB_SCHEMA}.test USING btree (name);
    CREATE INDEX test_msg_id on ${DB_SCHEMA}.test USING btree (type);
    CREATE INDEX test_network on ${DB_SCHEMA}.test USING btree (ts);
    CREATE INDEX test_lat on ${DB_SCHEMA}.test USING btree (val);

    -- A view to demonstrate that PostgREST exposes views as API endpoints too.
    CREATE VIEW ${DB_SCHEMA}.view_of_test AS
    SELECT
        name, ts, val
    FROM
        ${DB_SCHEMA}.test;

COMMIT;

-- Seed 500 random rows so the API has data to return immediately.
BEGIN;

INSERT INTO ${DB_SCHEMA}.test (name, type, ts, val)
SELECT
    md5(random()::text) AS column1,
    chr(65 + (random() * 25)::int) ||
    chr(65 + (random() * 25)::int) ||
    chr(65 + (random() * 25)::int) AS column2,
    (CURRENT_DATE - (random() * 365)::int)::DATE AS column3,
    (random() * 100)::NUMERIC(10, 2) AS column4
FROM
    generate_series(1, 500);

COMMIT;
END

# ---------------------------------------------------------------------------
# Step 4 — OpenAPI documentation comments (for demo table)
# ---------------------------------------------------------------------------
# PostgREST reads COMMENT ON objects and includes them in the auto-generated
# OpenAPI spec. Swagger UI then renders them as descriptions.
psql -U ${POSTGRES_USER} -d ${POSTGREST_DB} <<-END
    COMMENT ON SCHEMA ${DB_SCHEMA} IS
        'This is a example title for an automatically created API documentation.';

    COMMENT ON TABLE ${DB_SCHEMA}.test IS
        'This is a testing table/relation for PostgREST.';

    COMMENT ON COLUMN ${DB_SCHEMA}.test.id IS
    'The ID of this random stuff.';

    COMMENT ON COLUMN ${DB_SCHEMA}.test.name IS
    'The name of this random stuff.';

    COMMENT ON COLUMN ${DB_SCHEMA}.test.type IS
    'The type of this random stuff.';

    COMMENT ON COLUMN ${DB_SCHEMA}.test.ts IS
    'The timestamp of this random stuff.';

    COMMENT ON COLUMN ${DB_SCHEMA}.test.val IS
    'The value of this random stuff.';
END
