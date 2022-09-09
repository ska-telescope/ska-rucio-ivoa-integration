CREATE SCHEMA rucio;

CREATE TABLE rucio.dids ( 
    id                bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
    vo                character varying NOT NULL,
    scope             character varying NOT NULL,
    name              character varying NOT NULL, 
    data              jsonb DEFAULT '{}'::jsonb,
    UNIQUE            (scope, name)
);
