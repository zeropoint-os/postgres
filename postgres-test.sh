#!/bin/bash

# Simple Postgres connectivity test using docker exec + psql

CONTAINER_NAME="postgres-main"
USER="postgres"
DB="postgres"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: ${CONTAINER_NAME} container not found or not running"
    exit 1
fi

echo "Found ${CONTAINER_NAME}. Running test query..."

docker exec -i ${CONTAINER_NAME} psql -U ${USER} -d ${DB} -c "SELECT version();" || {
    echo "psql query failed"
    exit 1
}

echo "Postgres connectivity test succeeded."
