CREATE SCHEMA rucio;

CREATE TABLE rucio.dids ( 
    id                bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
    vo                character varying NOT NULL,
    scope             character varying NOT NULL,
    name              character varying NOT NULL, 
    data              jsonb DEFAULT '{}'::jsonb,
    UNIQUE            (scope, name)
);

CREATE TYPE rucio.obscore_row AS (
    rucio_did_scope   character varying,
    rucio_did_name    character varying,
    dataproduct_type  character varying,
    calib_level       integer,
    obs_collection    character varying,
    obs_id            character varying,
    obs_publisher_did character varying,
    access_url        text,
    access_format     character varying,
    access_estsize    bigint,
    target_name       character varying,
    s_ra              double precision,
    s_dec             double precision,
    s_fov             double precision,
    s_region          spoly,
    s_resolution      double precision,
    s_xel1            bigint,
    s_xel2            bigint,
    t_min             double precision,
    t_max             double precision,
    t_exptime         double precision,
    t_resolution      double precision,
    t_xel             bigint,
    em_min            double precision,
    em_max            double precision,
    em_res_power      double precision,
    em_xel            bigint,
    o_ucd             character varying,
    pol_states        character varying,
    pol_xel           bigint,
    facility_name     character varying,
    instrument_name   character varying
);

CREATE TABLE rucio.obscore OF rucio.obscore_row (
    rucio_did_scope   NOT NULL,
    rucio_did_name    NOT NULL,
    calib_level       NOT NULL,
    obs_collection    NOT NULL,
    obs_id            NOT NULL,
    obs_publisher_did NOT NULL,
    CONSTRAINT obscore_pkey PRIMARY KEY (rucio_did_scope, rucio_did_name),
    FOREIGN KEY (rucio_did_scope, rucio_did_name) REFERENCES rucio.dids (scope, name)
);

CREATE INDEX i_obscore_region ON rucio.obscore USING gist (s_region);

CREATE OR REPLACE FUNCTION rucio.upsert_obscore_record_from_rucio_metadata() RETURNS trigger AS
$$
BEGIN
        IF TG_OP = 'UPDATE' THEN
                /* Delete the record first as ON CONFLICT upsert requires fields to be invidually named. */
                DELETE FROM rucio.obscore WHERE rucio_did_scope = OLD.scope AND rucio_did_name = OLD.name;
        END IF;
    INSERT INTO rucio.obscore
                SELECT * FROM jsonb_populate_record(null::rucio.obscore_row, NEW.data || jsonb_build_object('rucio_did_scope', NEW.scope, 'rucio_did_name', NEW.name));
        RETURN NEW;
EXCEPTION
        WHEN not_null_violation THEN
	        RAISE NOTICE 'json data is missing a required, not-null field.';
        RETURN OLD;
END;
$$
  LANGUAGE 'plpgsql';

CREATE TRIGGER sync_rucio_dids_with_obscore
    AFTER INSERT OR UPDATE ON rucio.dids FOR EACH ROW
    EXECUTE FUNCTION rucio.upsert_obscore_record_from_rucio_metadata();
