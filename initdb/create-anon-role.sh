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
    CREATE INDEX gateways_ts on log.gateways USING btree (ts);
    CREATE INDEX gateways_lat on log.gateways USING btree (lat);
    CREATE INDEX gateways_lon on log.gateways USING btree (lon);
    CREATE INDEX gateways_alt on log.gateways USING btree (alt);
    CREATE INDEX gateways_name on log.gateways USING btree (name);
    CREATE INDEX gateways_eui_network_lat_lon_alt on log.gateways USING btree (eui,network,lat,lon,alt);

    CREATE INDEX msg_dev_eui on log.msg USING btree (dev_eui);
    CREATE INDEX msg_ts on log.msg USING btree (ts);
    CREATE INDEX msg_network on log.msg USING btree (network);
    CREATE INDEX msg_msg_id on log.msg USING btree (msg_id);

    CREATE OR REPLACE VIEW log.gateways_distinct AS
    SELECT *
    FROM
        (SELECT g.eui, MAX(g.ts) ts FROM log.gateways g GROUP BY eui) eui
    LEFT OUTER JOIN
        log.gateways g
    ON eui.eui = g.eui and eui.ts = g.ts
    ORDER BY g.eui, g.ts desc


    ORDER BY network, eui;

    CREATE OR REPLACE VIEW log.all AS
    SELECT * FROM (
        SELECT m.msg_id, m.dev_eui, m.ts, m.network, m.decoded_payload,
          m.confirmed, m.fcnt, m.port, m.bandwidth, m.frequency, m.spreading_factor,
          m.coding_rate, m.time_over_air, g.eui gateway_eui, g.snr, g.rssi, g.lat, g.lon, g.alt
        FROM log.gateways g,
            log.msg m
        WHERE m.msg_id = g.msg_id
    ) as sub
    ORDER BY ts desc;



    CREATE OR REPLACE VIEW log.gateways_per_msg AS
    SELECT * FROM (
        SELECT m.msg_id, m.dev_eui, m.ts, m.network, COUNT(*) gateway_count
        FROM log.gateways g,
            log.msg m
        WHERE m.msg_id = g.msg_id
        GROUP BY m.msg_id, m.dev_eui, m.ts, m.network
    ) as sub
    ORDER BY ts desc;


    CREATE OR REPLACE VIEW log.msg_per_gateway AS
    SELECT coord.eui, coord.network, coord.lat, coord.lon, cnt.count msg_count
    FROM (
        SELECT g.eui, COUNT(*)
        FROM log.gateways g, log.msg m
        WHERE g.msg_id = m.msg_id
        GROUP BY g.eui
    ) cnt,
    (
        SELECT DISTINCT ON (eui) g.eui, g.network, g.lat, g.lon
        FROM log.gateways g
        WHERE g.lat is not null AND g.lat > 0
        GROUP BY g.eui, g.network, g.lat, g.lon
    ) coord
    WHERE cnt.eui = coord.eui;

    CREATE OR REPLACE VIEW log.gateways_distinct AS
		SELECT DISTINCT ON (eui) *
        FROM log.gateways
        ORDER BY eui, ts desc nulls last;

    COMMIT;
END
