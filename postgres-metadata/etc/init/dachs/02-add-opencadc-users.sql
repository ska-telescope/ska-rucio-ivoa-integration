-- create user accounts
CREATE USER tapuser;
CREATE USER tapadm;

-- create TAP schemas
CREATE SCHEMA uws AUTHORIZATION tapadm;
CREATE SCHEMA IF NOT EXISTS tap_schema AUTHORIZATION tapadm;
CREATE SCHEMA tap_upload AUTHORIZATION tapuser;

-- apply permissions
GRANT USAGE ON SCHEMA tap_schema TO public;
GRANT SELECT ON ALL TABLES IN SCHEMA tap_schema TO public;
