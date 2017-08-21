FROM node:6

# Expose the HTTP port for OpenMCT
EXPOSE 8080
# Export the Websocket port for OpenMCT live telemetry
EXPOSE 8082

# Reduce npm install verbosity, overflows Travis CI log view
ENV NPM_CONFIG_LOGLEVEL warn

RUN mkdir -p /var/cbeam-telemetry-server
WORKDIR /var/cbeam-telemetry-server

COPY . /var/cbeam-telemetry-server

# Install MsgFlo and dependencies
RUN npm install

# Build OpenMCT
WORKDIR /var/cbeam-telemetry-server/node_modules/openmct
RUN npm install
RUN node ./node_modules/bower/bin/bower install --allow-root
RUN node ./node_modules/gulp/bin/gulp.js install

# Go back up
WORKDIR /var/cbeam-telemetry-server

# Map the volumes
VOLUME /var/cbeam-telemetry-server/config

CMD ./server.sh
