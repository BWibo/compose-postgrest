#!/bin/bash

psql -U ${POSTGRES_USER} <<-END
    CREATE DATABASE test;
    CREATE USER ${DB_ANON_ROLE};
END

psql -U ${POSTGRES_USER} -d test <<-END
    CREATE SCHEMA ${DB_SCHEMA};
END

psql -U ${POSTGRES_USER} -d test <<-END
    GRANT USAGE ON SCHEMA ${DB_SCHEMA} TO ${DB_ANON_ROLE};
    ALTER DEFAULT PRIVILEGES IN SCHEMA ${DB_SCHEMA} GRANT SELECT ON TABLES TO ${DB_ANON_ROLE};
    GRANT SELECT ON ALL SEQUENCES IN SCHEMA ${DB_SCHEMA} TO ${DB_ANON_ROLE};
    GRANT SELECT ON ALL TABLES IN SCHEMA ${DB_SCHEMA} TO ${DB_ANON_ROLE};
END

psql -U ${POSTGRES_USER} -d test <<-END
BEGIN;
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

    CREATE VIEW ${DB_SCHEMA}.view_of_test AS
    SELECT
        name, ts, val
    FROM
        ${DB_SCHEMA}.test;

COMMIT;

BEGIN;

INSERT INTO ${DB_SCHEMA}.test (name, type, ts, val)
SELECT
    md5(random()::text) AS column1,         -- Random string (hash of random number)
    chr(65 + (random() * 25)::int) ||      -- Random string starting with a random letter
    chr(65 + (random() * 25)::int) ||
    chr(65 + (random() * 25)::int) AS column2,
    (CURRENT_DATE - (random() * 365)::int)::DATE AS column3,  -- Random date within the past year
    (random() * 100)::NUMERIC(10, 2) AS column4  -- Random number between 0 and 100 with 2 decimals
FROM
    generate_series(1, 500);

COMMIT;
END

psql -U ${POSTGRES_USER} -d test <<-END
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
