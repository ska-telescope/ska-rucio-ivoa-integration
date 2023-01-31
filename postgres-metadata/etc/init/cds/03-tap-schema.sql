CREATE SCHEMA "TAP_SCHEMA";

-- TAP_SCHEMA

CREATE TABLE "TAP_SCHEMA"."schemas" ("schema_name" VARCHAR, "description" VARCHAR, "utype" VARCHAR, "dbname" VARCHAR, PRIMARY KEY("schema_name"));
CREATE TABLE "TAP_SCHEMA"."tables" ("schema_name" VARCHAR, "table_name" VARCHAR, "table_type" VARCHAR, "description" VARCHAR, "utype" VARCHAR, "dbname" VARCHAR, PRIMARY KEY("table_name"));
CREATE TABLE "TAP_SCHEMA"."coosys" ("id" VARCHAR, "system" VARCHAR, "equinox" VARCHAR, "epoch" VARCHAR, PRIMARY KEY("id"));
CREATE TABLE "TAP_SCHEMA"."columns" ("table_name" VARCHAR, "column_name" VARCHAR, "description" VARCHAR, "unit" VARCHAR, "ucd" VARCHAR, "utype" VARCHAR, "datatype" VARCHAR, "size" INTEGER, "principal" SMALLINT, "indexed" SMALLINT, "std" SMALLINT, "dbname" VARCHAR, "coosys_id" VARCHAR, PRIMARY KEY("table_name","column_name"));
CREATE TABLE "TAP_SCHEMA"."keys" ("key_id" VARCHAR, "from_table" VARCHAR, "target_table" VARCHAR, "description" VARCHAR, "utype" VARCHAR, PRIMARY KEY("key_id"));
CREATE TABLE "TAP_SCHEMA"."key_columns" ("key_id" VARCHAR, "from_column" VARCHAR, "target_column" VARCHAR, PRIMARY KEY("key_id"));

INSERT INTO "TAP_SCHEMA"."schemas" VALUES ('TAP_SCHEMA', 'Set of tables listing and describing the schemas, tables and columns published in this TAP service.', NULL, NULL);

INSERT INTO "TAP_SCHEMA"."tables" VALUES ('TAP_SCHEMA', 'TAP_SCHEMA.schemas', 'table', 'List of schemas published in this TAP service.', NULL, NULL);
INSERT INTO "TAP_SCHEMA"."tables" VALUES ('TAP_SCHEMA', 'TAP_SCHEMA.tables', 'table', 'List of tables published in this TAP service.', NULL, NULL);
INSERT INTO "TAP_SCHEMA"."tables" VALUES ('TAP_SCHEMA', 'TAP_SCHEMA.coosys', 'table', 'List of coordinate systems of coordinate columns published in this TAP service.', NULL, NULL);
INSERT INTO "TAP_SCHEMA"."tables" VALUES ('TAP_SCHEMA', 'TAP_SCHEMA.columns', 'table', 'List of columns of all tables listed in TAP_SCHEMA.TABLES and published in this TAP service.', NULL, NULL);
INSERT INTO "TAP_SCHEMA"."tables" VALUES ('TAP_SCHEMA', 'TAP_SCHEMA.keys', 'table', 'List all foreign keys but provides just the tables linked by the foreign key. To know which columns of these tables are linked, see in TAP_SCHEMA.key_columns using the key_id.', NULL, NULL);
INSERT INTO "TAP_SCHEMA"."tables" VALUES ('TAP_SCHEMA', 'TAP_SCHEMA.key_columns', 'table', 'List all foreign keys but provides just the columns linked by the foreign key. To know the table of these columns, see in TAP_SCHEMA.keys using the key_id.', NULL, NULL);

INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.schemas', 'schema_name', 'schema name, possibly qualified', NULL, NULL, NULL, 'VARCHAR', -1, 1, 1, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.schemas', 'description', 'brief description of schema', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.schemas', 'utype', 'UTYPE if schema corresponds to a data model', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.tables', 'schema_name', 'the schema name from TAP_SCHEMA.schemas', NULL, NULL, NULL, 'VARCHAR', -1, 1, 1, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.tables', 'table_name', 'table name as it should be used in queries', NULL, NULL, NULL, 'VARCHAR', -1, 1, 1, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.tables', 'table_type', 'one of: table, view', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.tables', 'description', 'brief description of table', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.tables', 'utype', 'UTYPE if table corresponds to a data model', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.coosys', 'id', 'ID of the coordinate system definition as it must be in the VOTable.', NULL, NULL, NULL, 'VARCHAR', -1, 1, 1, 0, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.coosys', 'system', 'The coordinate system among: ICRS, eq_FK5, eq_FK4, ecl_FK4, ecl_FK5, galactic, supergalactic, xy, barycentric, geo_app.', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 0, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.coosys', 'equinox', 'Required to fix the equatorial or ecliptic systems (as e.g. J2000 as the default for eq_FK5 or B1950 as the default for eq_FK4).', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 0, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.coosys', 'epoch', 'Epoch of the positions (if necessary).', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 0, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.columns', 'table_name', 'table name from TAP_SCHEMA.tables', NULL, NULL, NULL, 'VARCHAR', -1, 1, 1, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.columns', 'column_name', 'column name', NULL, NULL, NULL, 'VARCHAR', -1, 1, 1, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.columns', 'description', 'brief description of column', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.columns', 'unit', 'unit in VO standard format', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.columns', 'ucd', 'UCD of column if any', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.columns', 'utype', 'UTYPE of column if any', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.columns', 'datatype', 'ADQL datatype as in section 2.5', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.columns', 'size', 'length of variable length datatypes', NULL, NULL, NULL, 'INTEGER', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.columns', 'principal', 'a principal column; 1 means true, 0 means false', NULL, NULL, NULL, 'INTEGER', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.columns', 'indexed', 'an indexed column; 1 means true, 0 means false', NULL, NULL, NULL, 'INTEGER', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.columns', 'std', 'a standard column; 1 means true, 0 means false', NULL, NULL, NULL, 'INTEGER', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.columns', 'coosys_id', 'ID of the used coordinate systems (if any).', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 0, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.keys', 'key_id', 'unique key identifier', NULL, NULL, NULL, 'VARCHAR', -1, 1, 1, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.keys', 'from_table', 'fully qualified table name', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.keys', 'target_table', 'fully qualified table name', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.keys', 'description', 'description of this key', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.keys', 'utype', 'utype of this key', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.key_columns', 'key_id', 'unique key identifier', NULL, NULL, NULL, 'VARCHAR', -1, 1, 1, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.key_columns', 'from_column', 'key column name in the from_table', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('TAP_SCHEMA.key_columns', 'target_column', 'key column name in the target_table', NULL, NULL, NULL, 'VARCHAR', -1, 0, 0, 1, NULL);

-- ObsCore

INSERT INTO "TAP_SCHEMA"."schemas" VALUES ('ivoa', 'IVOA DM tables.', NULL, NULL);

INSERT INTO "TAP_SCHEMA"."tables" VALUES ('ivoa', 'ivoa.obscore', 'table', 'ObsCore 1.1.', NULL, NULL);

INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'dataproduct_type', 'Logical data set type (image, spectrum, visibility, cube, measurements, etc.)', NULL, 'meta.code.class', 'obscore:ObsDataset.dataProductType', 'VARCHAR', 12, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'calib_level', 'Calibration level: 0-instrument (raw) data in non-standard format, 1-instrumental (raw) data in standard format, 2-science ready data with instrument signature removed, 3-more highly processed data.', NULL, 'meta.code;obs.calib', 'obscore:ObsDataset.calibLevel', 'INTEGER', NULL, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'obs_collection', 'The name of the data collection the data set belongs to.', NULL, 'meta.id', 'obscore:DataID.collection', 'VARCHAR', 128, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'obs_id', 'In case multiple data sets are available for an observation, e.g. with different calibration levels, the obs_id value will be the same for each data set the observation comprises. The obs_id should remain identical through time for future reference.', NULL, 'meta.id', 'obscore:DataID.observationID', 'VARCHAR', 255, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'obs_publisher_did', 'IVOA dataset identifier for the published data set. It must be unique within the namespace controlled by the publisher.', NULL, 'meta.ref.ivoid', 'obscore:Curation.publisherDID', 'VARCHAR', 128, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'access_url', 'A URL that points to the DataLink (VO Standard) service that is used to download the dataset, associated files, their provenance or derived products, etc.', NULL, 'meta.ref.url', 'obscore:Access.reference', 'VARCHAR', 1024, 1, 0, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'access_format', 'The format of the downloaded file.', NULL, 'meta.code.mime', 'obscore:Access.format', 'VARCHAR', 56, 1, 0, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'access_estsize', 'Estimated size of the downloaded file in KBytes.', 'kbyte', 'phys.size;meta.file', 'obscore:Access.size', 'BIGINT', NULL, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'target_name', 'The target name.', NULL, 'meta.id;src', 'obscore:Target.name', 'VARCHAR', 256, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 's_ra', 'Equatorial coordinate: Right Ascension (FK5/J2000).', 'deg', 'pos.eq.ra', 'obscore:Char.SpatialAxis.Coverage.Location.Coord.Position2D.Value2.C1', 'DOUBLE PRECISION', NULL, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 's_dec', 'Equatorial coordinate: Declination (FK5/J2000.', 'deg', 'pos.eq.dec', 'obscore:Char.SpatialAxis.Coverage.Location.Coord.Position2D.Value2.C2', 'DOUBLE PRECISION', NULL, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 's_fov', 'Angular size of the spatial field of view the photons were collected from.', 'deg', 'phys.angSize;instr.fov', 'obscore:Char.SpatialAxis.Coverage.Bounds.Extent.diameter', 'DOUBLE PRECISION', NULL, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 's_region', 'The spatial footprint of the data set.', NULL, 'pos.outline;obs.field', 'obscore:Char.SpatialAxis.Coverage.Support.Area', 'VARCHAR', NULL, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 's_resolution', 'The characteristic spatial resolution of the data set.', 'arcsec', 'pos.angResolution', 'obscore:Char.SpatialAxis.Resolution.Refval.value', 'DOUBLE PRECISION', NULL, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 's_xel1', 'Number of elements (e.g. pixels) along the first spatial axis.', NULL, 'meta.number', 'obscore:Char.SpatialAxis.numBins1', 'BIGINT', NULL, 1, 0, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 's_xel2', 'Number of elements (e.g. pixels) along the second spatial axis.', NULL, 'meta.number', 'obscore:Char.SpatialAxis.numBins2', 'BIGINT', NULL, 1, 0, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 't_min', 'Start time in MJD.', 'd', 'time.start;obs.exposure', 'obscore:Char.TimeAxis.Coverage.Bounds.Limits.StartTime', 'DOUBLE PRECISION', NULL, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 't_max', 'Stop time in MJD.', 'd', 'time.end;obs.exposure', 'obscore:Char.TimeAxis.Coverage.Bounds.Limits.StopTime', 'DOUBLE PRECISION', NULL, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 't_exptime', 'Total integration time per pixel (in seconds).', 's', 'time.duration;obs.exposure', 'obscore:Char.TimeAxis.Coverage.Support.Extent', 'DOUBLE PRECISION', NULL, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 't_resolution', 'Temporal resolution in seconds.', 's', 'time.resolution', 'obscore:Char.TimeAxis.Resolution.Refval.value', 'DOUBLE PRECISION', NULL, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 't_xel', 'Number of elements along the time axis.', NULL, 'meta.number', 'obscore:Char.TimeAxis.numBins', 'BIGINT', NULL, 1, 0, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'em_min', 'Minimum spectral value observed, expressed in vacuum wavelength in metres.', 'm', 'em.wl;stat.min', 'obscore:Char.SpectralAxis.Coverage.Bounds.Limits.LoLimit', 'DOUBLE PRECISION', NULL, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'em_max', 'Maximum spectral value observed, expressed in vacuum wavelength in metres.', 'm', 'em.wl;stat.max', 'obscore:Char.SpectralAxis.Coverage.Bounds.Limits.HiLimit', 'DOUBLE PRECISION', NULL, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'em_res_power', 'The characteristic spectral resolving power (lambda/delta(lambda)) of the data set.', NULL, 'spect.resolution', 'obscore:Char.SpectralAxis.Resolution.ResolPower.refVal', 'DOUBLE PRECISION', NULL, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'em_xel', 'Number of elements on the spectral axis.', NULL, 'meta.number', 'obscore:Char.SpectralAxis.numBins', 'BIGINT', NULL, 1, 0, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'o_ucd', 'Nature of the observable within the data set, expressed as an Uniform Content Descriptor (IVOA standard).', NULL, 'meta.ucd', 'obscore:Char.ObservableAxis.ucd', 'VARCHAR', 64, 1, 0, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'pol_states', 'A list of the polarisation states present in the data set. It is serialised as a concatenated list of the possible values: {I Q U V RR LL RL LR XX YY XY YX POLI POLA} where the list separator is a slash /. Leading and trailing slashes must always be present; example: /YY/.', NULL, 'meta.code;phys.polarization', 'obscore:Char.PolarizationAxis.stateList', 'VARCHAR', 32, 1, 0, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'pol_xel', 'Number of polarisation states available in the data set.', NULL, 'meta.number', 'obscore:Char.PolarizationAxis.numBins', 'BIGINT', NULL, 1, 0, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'facility_name', 'Name of the telescope utilised to gather the photons.', NULL, 'meta.id;instr.tel', 'obscore:Provenance.ObsConfig.Facility.name', 'VARCHAR', 68, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'instrument_name', 'Name of the instrument(s) utilised to gather the data.', NULL, 'meta.id;instr', 'obscore:Provenance.ObsConfig.Instrument.name', 'VARCHAR', 68, 1, 1, 1, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'rucio_did_scope', 'Rucio specific field not present in the standard ObsCore DM. Scope of the Rucio DID.', NULL, 'meta.id', NULL, 'VARCHAR', 128, 0, 1, 0, NULL, NULL);
INSERT INTO "TAP_SCHEMA"."columns" VALUES ('ivoa.obscore', 'rucio_did_name', 'Rucio specific field not present in the standard ObsCore DM. Scope of the Rucio DID.', NULL, 'meta.id', NULL, 'VARCHAR', 128, 0, 1, 0, NULL, NULL);

