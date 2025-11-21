-- create youcat user accounts
CREATE USER tapuser;
CREATE USER tapadm;

--  create the DACHS gavoadmin user to set user permissions
CREATE USER gavoadmin;

-- create TAP schemas
CREATE SCHEMA tap_schema AUTHORIZATION gavoadmin;
CREATE SCHEMA tap_upload AUTHORIZATION tapuser;
CREATE SCHEMA uws AUTHORIZATION tapadm;

-- apply permissions
GRANT CREATE ON SCHEMA tap_schema TO tapadm;
GRANT USAGE ON SCHEMA tap_schema TO tapadm;

-- give gavoadmin it's expected permissions of create and usage on the tap_schema
GRANT CREATE ON SCHEMA tap_schema TO gavoadmin;
GRANT USAGE ON SCHEMA tap_schema TO gavoadmin;
