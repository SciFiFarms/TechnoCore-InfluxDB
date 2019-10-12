#!/usr/bin/env bash
# Most of this file comes from https://medium.com/@basi/docker-environment-variables-expanded-from-secrets-8fa70617b3bc 
# Thanks Basilio Vera, Rubén Norte, and Jose Manuel Cardona! 

: ${ENV_SECRETS_DIR:=/run/secrets}

env_secret_debug()
{
    if [ ! -z "$ENV_SECRETS_DEBUG" ]; then
        echo -e "\033[1m$@\033[0m"
    fi
}

# usage: env_secret_expand VAR
#    ie: env_secret_expand 'XYZ_DB_PASSWORD'
# (will check for "$XYZ_DB_PASSWORD" variable value for a placeholder that defines the
#  name of the docker secret to use instead of the original value. For example:
# XYZ_DB_PASSWORD={{DOCKER-SECRET:my-db.secret}}
env_secret_expand() {
    var="$1"
    eval val=\$$var
    if secret_name=$(expr match "$val" "{{DOCKER-SECRET:\([^}]\+\)}}$"); then
        secret="${ENV_SECRETS_DIR}/${secret_name}"
        env_secret_debug "Secret file for $var: $secret"
        if [ -f "$secret" ]; then
            val=$(cat "${secret}")
            export "$var"="$val"
            env_secret_debug "Expanded variable: $var=$val"
        else
            env_secret_debug "Secret file does not exist! $secret"
        fi
    fi
}

env_secrets_expand() {
    for env_var in $(printenv | cut -f1 -d"=")
    do
        env_secret_expand $env_var
    done

    if [ ! -z "$ENV_SECRETS_DEBUG" ]; then
        echo -e "\n\033[1mExpanded environment variables\033[0m"
        printenv
    fi
}
env_secrets_expand

# Add any additional script here. 
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

exec "$@"
