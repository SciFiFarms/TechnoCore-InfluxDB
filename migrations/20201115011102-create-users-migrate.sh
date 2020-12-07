#!/usr/bin/env bash
# Some bits modified from: https://github.com/influxdata/influxdata-docker/blob/master/influxdb/1.8/init-influxdb.sh

INFLUX_CMD="influx -host 127.0.0.1 -username $INFLUXDB_ADMIN_USER -password $(cat /run/secrets/admin_password) -execute "

# Wait until InfluxDB is online. 
# https://docs.influxdata.com/influxdb/v1.8/tools/api/#ping-http-endpoint
until curl -sL -I localhost:8086/ping?wait_for_leader=30s; do
    sleep 5
done

echo 
for service_path in /run/secrets/users/*; do
    service=$(basename "$service_path")

    # TODO: This should check if the password is actually set. 
    if echo "Not yet set." | grep "$(cat "$service_path")"; then
        echo "Password is 'Not yet set.' Please set before creating user."
        exit 1
    fi

    # Only allow Home Assistant to write data. 
    if echo "home_assistant" | grep "$service"; then
        echo "Creating read/write account for service: $service"
        $INFLUX_CMD "CREATE USER \"$service\" WITH PASSWORD '$(cat "$service_path")'"
        $INFLUX_CMD "REVOKE ALL PRIVILEGES FROM \"$service\""

        if [ -n "$INFLUXDB_DB" ]; then
            $INFLUX_CMD "GRANT WRITE ON \"$INFLUXDB_DB\" TO \"$service\""
        fi
    else
        echo "Creating read only account for service: $service"
        $INFLUX_CMD "CREATE USER \"$service\" WITH PASSWORD '$(cat "$service_path")'"
        $INFLUX_CMD "REVOKE ALL PRIVILEGES FROM \"$service\""

        if [ -n "$INFLUXDB_DB" ]; then
            $INFLUX_CMD "GRANT READ ON \"$INFLUXDB_DB\" TO \"$service\""
        fi
    fi
done
