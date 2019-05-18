#!/usr/bin/env bash

if cat /run/secrets/admin_password | grep "Not yet set." &> /dev/null; then
    echo "Credentials not yet set. Waiting until they are set."
    # It'll automatically reboot when the credentials are added.
    sleep 1000d
fi

# https://unix.stackexchange.com/questions/79068/how-to-export-variables-that-are-set-all-at-once
set -a
    # TODO: Rather than only set these users when the DB is initialized, they should be idempotently set. 
    INFLUXDB_ADMIN_USER=$(cat /run/secrets/admin_username)
    INFLUXDB_ADMIN_PASSWORD=$(cat /run/secrets/admin_password)

    # Could consider using WRITE_USER instead.
    INFLUXDB_USER=$(cat /run/secrets/home_assistant_username)
    INFLUXDB_USER_PASSWORD=$(cat /run/secrets/home_assistant_password)
    INFLUXDB_READ_USER=$(cat /run/secrets/grafana_username)
    INFLUXDB_READ_USER_PASSWORD=$(cat /run/secrets/grafana_password)
set +a

# Launch Influx
/entrypoint.sh influxd
