START TRANSACTION;

-- creates and manages all tables for youcat
CREATE USER tapadm WITH PASSWORD 'pw-tapadm';

-- for executing queries that are submitted using the TAP API
CREATE USER tapuser WITH PASSWORD 'pw-tapuser';

-- give tapadm privileges to create and access tables in the tap_schema
-- CREATE SCHEMA tap_schema AUTHORIZATION tapadm; -- for a standalone youcat tap service

-- gavoadmin (dachs) owns the tap_schema schema and has full privileges,
-- tapadm needs privileges to create and access tables, and to grant privileges in the tap_schema,
-- this grants tapadm privileges to the dachs tables, as gavoadmin has to the youcat tables,
-- however the services use separate tables in the tap_schema and shouldn't affect each other
GRANT ALL ON SCHEMA tap_schema TO tapadm;
GRANT gavoadmin to tapadm;

-- allow tapuser to read (query)the rucio table
GRANT USAGE ON SCHEMA rucio TO tapuser;
GRANT SELECT ON TABLE rucio.obscore TO tapuser;

-- schema for the youcat UWS job tables
CREATE SCHEMA uws AUTHORIZATION tapadm;

-- schema for the user upload tables
CREATE SCHEMA tap_upload AUTHORIZATION tapuser;

COMMIT TRANSACTION;
