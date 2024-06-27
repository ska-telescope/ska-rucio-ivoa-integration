#!/bin/bash

export SERVICE_VERSION=`cat VERSION`

cd /opt/rucio_datalink/src/rucio_datalink/rest

# run server in bg
uvicorn server:app --host "0.0.0.0" --port $SERVICE_DATALINK_PORT --reload --reload-dir ../../../etc/ --reload-include *.xml

