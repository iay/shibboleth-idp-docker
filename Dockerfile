#
# Shibboleth Identity Provider
#
# Builds a partial image for running the Shibboleth Identity Provider.
#
# This includes Java, Jetty and the Jetty configuration. At present,
# the IdP itself and its configuration are mounted into the container.
#

#
# The base Java image to use is determined by a build argument.
# This defaults to the lowest version of Corretto supported by
# current IdP versions, but is normally overridden by the VERSIONS
# file via the build script.
#
ARG JAVA_VERSION=amazoncorretto:17

#
# This image is based on the Alpine Linux variant of the Java container.
#
FROM ${JAVA_VERSION}-alpine

LABEL org.opencontainers.image.authors="Ian Young <ian@iay.org.uk>"

#
# Jetty itself lives in JETTY_HOME.
#
ENV JETTY_HOME=/opt/jetty

#
# The Jetty base lives in JETTY_BASE, outside the Shibboleth IdP.
#
ENV JETTY_BASE=/opt/jetty-base

#
# A subdirectory of JETTY_BASE is used for Jetty's logs, and is
# exposed as a volume.
#
ENV JETTY_LOGS=${JETTY_BASE}/logs
VOLUME ["${JETTY_LOGS}"]

ENV IDP_HOME=/opt/shibboleth-idp

#
# Alpine Linux containers are a lot smaller, but don't have any additional
# components. We need to add "curl" for the health check.
#
RUN apk add --no-cache curl

#
# Add the Jetty base.
#
ARG JETTY_BASE_VERSION
ADD jetty-base-${JETTY_BASE_VERSION} ${JETTY_BASE}

#
# Add the Jetty distribution.
#
ARG JETTY_VERSION
ADD jetty-dist-${JETTY_VERSION}/dist ${JETTY_HOME}

EXPOSE 80 443 8443

VOLUME ["${IDP_HOME}"]

WORKDIR ${JETTY_BASE}
CMD ["java",\
    "-Djdk.tls.ephemeralDHKeySize=2048", \
    "-Didp.home=/opt/shibboleth-idp", \
    "-Djetty.base=/opt/jetty-base",\
    "-Djetty.logs=/opt/jetty-base/logs",\
    "-jar", "/opt/jetty/start.jar"]

#
# Add Jetty configuration overlay from a tar archive.
#
ADD overlay/jetty-base-${JETTY_BASE_VERSION}.tar ${JETTY_BASE}

#
# Health check for the container.
#
# -f == --fail        don't show message on server failures
# -s == --silent      don't show progress bar or error message
#
HEALTHCHECK --interval=1m --timeout=30s \
    CMD curl -f -s http://127.0.0.1/idp/status || exit 1

#
# End.
#
