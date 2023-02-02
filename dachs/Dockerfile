FROM gavodachs/server 

ENV GAVORC_SERVER_URL=http://localhost:8080
ENV GAVORC_SERVER_PORT=8080
ENV DACHS_POSTGRES_HOST=postgres-metadata
ENV DACHS_POSTGRES_DBNAME=metadata

RUN apt-get update -y && apt-get install -y gettext-base odbc-postgresql python3-pyodbc

# copy in gavo config and make environment subsitutions
COPY etc/dachs/gavo.rc.template /tmp/gavo.rc.template
RUN cat /tmp/gavo.rc.template | envsubst > /etc/gavo.rc

# RD
RUN mkdir -p /tmp/inputs

## 1. RD using odbcGrammar and external database connection
### make tmp directory (must be copied in to /var/gavo/inputs on init)
COPY etc/dachs/inputs/externaldb /tmp/inputs/externaldb

### subsitute envvars into driver connection string
RUN cat /tmp/inputs/externaldb/data/driver.template | envsubst > /tmp/inputs/externaldb/data/driver

## 2. RD using externally managed table
### make directory (must be copied in to /var/gavo/inputs on init)
COPY etc/dachs/inputs/rucio /tmp/inputs/rucio

COPY etc/docker/init.sh /init.sh
ENTRYPOINT ["/bin/bash", "init.sh"]
