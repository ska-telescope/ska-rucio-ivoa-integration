FROM postgres:14

RUN apt-get update -y && apt-get install -y wget cmake postgresql-server-dev-14

RUN wget -qO- https://github.com/akorotkov/pgsphere/archive/master.tar.gz | tar xvz
RUN (cd pgsphere-master && make CFLAGS=-std=c99 USE_PGXS=1 PG_CONFIG=/usr/bin/pg_config)
RUN (cd pgsphere-master && make CFLAGS=-std=c99 USE_PGXS=1 PG_CONFIG=/usr/bin/pg_config install)

COPY etc/init/* /docker-entrypoint-initdb.d/ 
