# SKA Rucio IVOA Integration

## Architecture

This integration demonstrates how to integrate an IVOA TAP service with an external Rucio metadata postgres database. Two technology stacks are currently supported:

- the [TAP library from CDS]((http://cdsportal.u-strasbg.fr/taptuto/index.html))
- [DaCHS](https://docs.g-vo.org/DaCHS/), and

It is comprised of five microservices, a combination of which need to be run for each stack. That is, one of 

- an instance of Apache Tomcat running the CDS Tap library servlet (`tomcat-tap`), or
- an instance of DaCHS (`dachs`)

needs to be run along with a set of common services, some of which are optional: 

1. an instance of postgres with the [pgSphere](https://pgsphere.github.io/) extension enabled and necessary schema (`postgres-metadata`), and 
2. (optional) a jupyter notebook with example TAP query code using [pyvo](https://pypi.org/project/pyvo/) (`jupyter`), and 
3. (optional) a pgadmin4 instance connected with preopopulated parameters for the postgres backend (sandbox only)

Depending on the stack, the `postgres-metadata` service exposes a database with the necessary schema.

Two compose files are available for local development and sandboxed (with path prefixes).

### CDS Tap Library

The backend for the CDS Tap library has the following:

- A schema, `TAP_SCHEMA`, that contains the necessary tables to expose a TAP service (essentially a record of what tables/columns/keys the IVOA service uses),
- A table, `dids`, under schema `rucio`, that "mocks" the table that the external postgres Rucio metadata interface interacts with. This table has nothing to do with IVOA, and is used to hold arbitrary Rucio metadata,
- A table, `obscore`, under schema `ivoa`, that contains the necessary columns for a TAP service to interact with according to the [ObsCore 1.1 DM](https://www.ivoa.net/documents/ObsCore/), and
- A function and trigger that updates the `ivoa.obscore` table from `rucio.dids` everytime there is an `INSERT` or `UPDATE` statement

The function to insert/update records in the `ivoa.obscore` table is set up in such a way that updates to the `rucio.dids.data` column will first delete any row where both `rucio.dids.scope` = `ivoa.obscore.rucio_did_scope` and `rucio.dids.name` = `ivoa.obscore.rucio_did_name` before inserting, i.e. the function is essentially an upsert, keeping data in sync between the two tables.

#### Endpoints

##### Local

| Service | Port | Landing page | Default user | Default password | Other credentials |
|---------|------|--------------|--------------|------------------|-------------------|
| tomcat-tap | 8080 | http://localhost:8080/tapserver/tap | | | |
| jupyter-vo | 8888 | http://localhost:8888/jupyter/lab| | secret |  |
| postgres-metadata | 5432 | | postgres | secret | database=metadata |

##### Sandbox

| Service | Port | Landing page | Default user | Default password | Other credentials |
|---------|------|--------------|--------------|------------------|-------------------|
| tomcat-tap | 8080 | http://localhost:8080/ivoa/tapserver/tap | | | |
| jupyter-vo | 8888 | http://localhost:8888/ivoa/jupyter/lab | | secret |  |
| postgres-metadata | 5432 | | postgres | secret | database=metadata |
| pgadmin4 | 8889 | http://localhost:8889 | | secret | |

#### Considerations

Three methods of architecting the database were considered:

1. Having a view that constructs the necessary columns from the `rucio.dids` table directly,
2. Having the `rucio.dids` table conform to the schema required by `ivoa.obscore`, and 
3. Building another **table** and using a trigger to sync the data.

Each of these methods has pros/cons. 

Using a view (1) is conceptually simpler and reduces data duplication. It does however raise a couple of questions about how performant reading fields from a json array is (a view, after all, is essentially a glorified SELECT query). It also limits the ability to physically relocate data on disk for faster reading (clustering).

Creating a single table (2) initially seems appealing, but requires  development on the external Rucio metadata plugin to be able to handle columnar data rather than just dumping all metadata fields into a single JSON column (as is currently the only supported mode of operation). It is possible that a "hybrid" Rucio postgresql metadata extension could be developed that inserts metadata into columns if the keys for the metadata exist as columns in the metadata table, but otherwise into a "catch-all" JSON column. All this however would blur the demarcation between Rucio and IVOA DBA.

Building another table and creating triggers (3) clearly demarcates what is handled by Rucio and what is an IVOA resource, but as mentioned, creates data duplication.

#### Deployment

##### Local

These services can be build and brought up using `docker-compose`, specifying the build argument `POSTGRES_INIT_DIR=cds`:

```bash
$ docker-compose build --build-arg POSTGRES_INIT_DIR=cds postgres tomcat jupyter
$ docker-compose up tomcat jupyter postgres
```

##### Sandbox

If exposing externally, remember to set:

- `JUPYTER_SERVER_PASSWORD` for authentication with the jupyter notebook server,
- `JUPYTER_SERVER_BASE_URL` if the base URL of the jupyter service is anything other than `/`, and
- `TOMCAT_TAPSERVER_BASE_URL` if the base URL of the Tomcat TAP server service is anything other than `/tapserver`.

It is possible to use docker-compose overrides to separate these variables, e.g. 

```bash
$ docker-compose -f docker-compose.yml -f docker-compose.sandbox.yml build --build-arg POSTGRES_INIT_DIR=cds postgres tomcat jupyter pgadmin
$ docker-compose -f docker-compose.yml -f docker-compose.sandbox.yml up tomcat jupyter postgres pgadmin`
```

### DaCHS

#### Endpoints

##### Local

| Service | Port | Landing page | Default user | Default password | Other credentials |
|---------|------|--------------|--------------|------------------|-------------------|
| dachs| 8080 | http://localhost:8080/ | | | |
| jupyter-vo | 8888 | http://localhost:8888/jupyter/lab| | secret |  |
| postgres-metadata | 5432 | | postgres | secret | database=metadata |

##### Sandbox

TBD

#### Deployment

##### Local

These services can be build and brought up using `docker-compose`, specifying the build argument `POSTGRES_INIT_DIR=dachs`:

```bash
$ docker-compose build --build-arg POSTGRES_INIT_DIR=dachs postgres dachs jupyter
$ docker-compose up dachs jupyter postgres
```

##### Sandbox

If exposing externally, remember to set:

- `JUPYTER_SERVER_PASSWORD` for authentication with the jupyter notebook server,
- `JUPYTER_SERVER_BASE_URL` if the base URL of the jupyter service is anything other than `/`, and

It is possible to use docker-compose overrides to separate these variables, e.g. 

```bash
$ docker-compose -f docker-compose.yml -f docker-compose.sandbox.yml build --build-arg POSTGRES_INIT_DIR=dachs postgres dachs jupyter pgadmin
$ docker-compose -f docker-compose.yml -f docker-compose.sandbox.yml up dachs jupyter postgres pgadmin`
```

## Future

This may be a good candidate for distributed SQL, e.g. yugabyte, citus. With yugabyte it is possible to have multiple [RO replicas](https://docs.yugabyte.com/preview/architecture/docdb-replication/read-replicas/) where each SRC could have its own metadata database but with a singular source of truth.






