#!/bin/sh

psql -c "CREATE EXTENSION q3c;" $POSTGRES_DB
echo "Loaded q3c extension in database $POSTGRES_DB"

psql -c "CREATE EXTENSION pg_sphere;" $POSTGRES_DB
echo "Loaded pgsphere extension in database $POSTGRES_DB"
