FROM influxdb:1.8.3
#ENV INFLUXDB_HTTP_HTTPS_ENABLED true
#ENV INFLUXDB_HTTP_HTTPS_CERTIFICATE /run/secrets/cert_bundle
#ENV INFLUXDB_HTTP_HTTPS_PRIVATE_KEY /run/secrets/key
ENV INFLUXDB_HTTP_AUTH_ENABLED true
ENV INFLUXDB_DB home_assistant

# Add dogfish
# This should be set to where the volume mounts to.
ARG PERSISTANT_DIR=/var/lib/influxdb
COPY dogfish/ /usr/share/dogfish
COPY migrations/ /usr/share/dogfish/shell-migrations
RUN ln -s /usr/share/dogfish/dogfish /usr/bin/dogfish
RUN mkdir /var/lib/dogfish 
# Need to do this all together because ultimately, the config folder is a volume, and anything done in there will be lost. 
RUN mkdir -p ${PERSISTANT_DIR} && touch ${PERSISTANT_DIR}/migrations.log && ln -s ${PERSISTANT_DIR}/migrations.log /var/lib/dogfish/migrations.log 

## Set up the CMD as well as the pre and post hooks.
COPY go-init /bin/go-init
COPY entrypoint.sh /usr/bin/entrypoint.sh
COPY exitpoint.sh /usr/bin/exitpoint.sh

ENTRYPOINT ["go-init"]
CMD ["-main", "/usr/bin/entrypoint.sh /entrypoint.sh influxd", "-post", "/usr/bin/exitpoint.sh"]
