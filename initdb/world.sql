--
-- PostgreSQL port of the MySQL "World" database.
--
-- The sample data used in the world database is Copyright Statistics
-- Finland, http://www.stat.fi/worldinfigures.
--

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
	Primary key msg_id varchar(16) NULL,
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

COMMIT;
