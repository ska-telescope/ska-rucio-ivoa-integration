#!/bin/sh

psql -c "CREATE EXTENSION pg_sphere;" $POSTGRES_DB
echo "Loaded pgsphere extension in database $POSTGRES_DB"
