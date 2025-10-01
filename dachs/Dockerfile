FROM gavodachs/server 

#FIXME: these should be consumed after build time (i.e. envsubst commands should be run in init script)
ENV GAVORC_SERVER_URL=http://localhost:8080
ENV GAVORC_SERVER_PORT=8080
ENV DACHS_POSTGRES_HOST=postgres-metadata
ENV DACHS_POSTGRES_DBNAME=metadata
ENV IVOA_AUTHORITY=test.skao

# get the new GAVO APT repository key
RUN echo "deb http://vo.ari.uni-heidelberg.de/debian release main" \
        > /etc/apt/sources.list.d/gavo.list                         && \
    wget -qO - http://docs.g-vo.org/archive-key.asc | apt-key add -

RUN apt-get update -y && apt-get install -y gettext-base odbc-postgresql python3-pyodbc

# copy in template gavo config 
COPY etc/dachs/gavo.rc.template /tmp/gavo.rc.template

# RD
RUN mkdir -p /tmp/inputs

## 1. RD using odbcGrammar and external database connection
### make tmp directory (must be copied in to /var/gavo/inputs on init)
COPY etc/dachs/inputs/externaldb /tmp/inputs/externaldb

## 2. RD using externally managed table
### make directory (must be copied in to /var/gavo/inputs on init)
COPY etc/dachs/inputs/rucio /tmp/inputs/rucio

COPY etc/docker/init.sh /init.sh
ENTRYPOINT ["/bin/bash", "init.sh"]
