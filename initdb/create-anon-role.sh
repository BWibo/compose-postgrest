#!/bin/bash

psql -U ${POSTGRES_USER} <<-END
    CREATE DATABASE logging;
    CREATE USER ${DB_ANON_ROLE};
END

psql -U ${POSTGRES_USER} -d logging <<-END
    GRANT USAGE ON SCHEMA ${DB_SCHEMA} TO ${DB_ANON_ROLE};
    ALTER DEFAULT PRIVILEGES IN SCHEMA ${DB_SCHEMA} GRANT SELECT ON TABLES TO ${DB_ANON_ROLE};
    GRANT SELECT ON ALL SEQUENCES IN SCHEMA ${DB_SCHEMA} TO ${DB_ANON_ROLE};
    GRANT SELECT ON ALL TABLES IN SCHEMA ${DB_SCHEMA} TO ${DB_ANON_ROLE};

END

psql -U ${POSTGRES_USER} -d logging <<-END
    BEGIN;
    CREATE TABLE gateways (
        network varchar(5) NULL,
        eui varchar(16) NULL,
        msg_id varchar(16) NULL,
        rssi float4 NULL,
        snr float4 NULL,
        lat float4 NULL,
        lon float4 NULL,
        alt float4 NULL
    );

    CREATE TABLE msg (
        network varchar(5) NULL,
        ts timestamptz NULL,
        dev_eui varchar(16) NULL,
        msg_id varchar(16) PRIMARY KEY,
        decoded_payload jsonb NULL,
        payload varchar(512) NULL,
        confirmed bool NULL,
        fcnt int4 NULL,
        port int4 NULL,
        bandwidth int4 NULL,
        frequency int8 NULL,
        spreading_factor int4 NULL,
        coding_rate varchar(12) NULL,
        time_over_air varchar(12) NULL
    );

    CREATE INDEX gateways_eui on gateways USING btree (eui);
    CREATE INDEX gateways_msg_id on log.gateways USING btree (msg_id);
    CREATE INDEX gateways_network on log.gateways USING btree (network);
    CREATE INDEX msg_dev_eui on log.msg USING btree (dev_eui);


    CREATE OR REPLACE VIEW log.gateways_distinct AS
    SELECT * FROM (
        SELECT DISTINCT ON (eui) g.eui, g.network, g.lat, g.lon, g.alt
        FROM log.gateways g
    ) as sub
    ORDER BY network, eui;


        network varchar(5) NULL,
        eui varchar(16) NULL,
        msg_id varchar(16) NULL,
        rssi float4 NULL,
        snr float4 NULL,
        lat float4 NULL,
        lon float4 NULL,
        alt float4 NULL

    CREATE OR REPLACE VIEW log.all AS
    SELECT * FROM (
        SELECT m.msg_id, m.dev_eui, m.ts, m.network, m.decoded_payload,
          m.confirmed, m.fcnt, m.port, m.bandwidth, m.frequency, m.spreading_factor,
          m.coding_rate, m.time_over_air, g.eui gateway_eui, g.snr, g.lat, g.lon, g.alt
        FROM log.gateways g,
            log.msg m
        WHERE m.msg_id = g.msg_id
    ) as sub
    ORDER BY ts desc;


    COMMIT;
END
