FROM influxdb:1.7.6
#ENV INFLUXDB_HTTP_HTTPS_ENABLED true
#ENV INFLUXDB_HTTP_HTTPS_CERTIFICATE /run/secrets/cert_bundle
#ENV INFLUXDB_HTTP_HTTPS_PRIVATE_KEY /run/secrets/key
ENV INFLUXDB_HTTP_AUTH_ENABLED true
ENV INFLUXDB_DB home_assistant

## Set up the CMD as well as the pre and post hooks.
COPY go-init /bin/go-init
COPY entrypoint.sh /usr/bin/entrypoint.sh
COPY exitpoint.sh /usr/bin/exitpoint.sh

ENTRYPOINT ["go-init"]
CMD ["-main", "/usr/bin/entrypoint.sh", "-post", "/usr/bin/exitpoint.sh"]
