FROM gavodachs/server

#FIXME: these should be consumed after build time (i.e. envsubst commands should be run in init script)
ENV GAVORC_SERVER_URL=http://localhost:8080
ENV GAVORC_SERVER_PORT=8080
ENV DACHS_POSTGRES_HOST=postgres-metadata
ENV DACHS_POSTGRES_DBNAME=metadata
ENV IVOA_AUTHORITY=test.skao

# Replace sources with known-good Bullseye repos and drop third-party lists
RUN set -eux; \
  printf '%s\n' \
    'deb http://deb.debian.org/debian bullseye main' \
    'deb http://security.debian.org/debian-security bullseye-security main' \
    'deb http://deb.debian.org/debian bullseye-updates main' \
    > /etc/apt/sources.list; \
  rm -f /etc/apt/sources.list.d/*.list || true; \
  apt-get update -y; \
  apt-get install -y --no-install-recommends \
    gettext-base unixodbc odbc-postgresql python3-pyodbc; \
  rm -rf /var/lib/apt/lists/*

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
