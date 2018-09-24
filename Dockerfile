#
# idp-builder dockerfile
#

#
# The base Java image to use is determined by a build argument.
#
ARG JAVA_VERSION
FROM ${JAVA_VERSION}

MAINTAINER Ian Young <ian@iay.org.uk>

ENV JETTY_HOME=/opt/jetty
ENV IDP_HOME=/opt/shibboleth-idp
ENV JETTY_BASE=${IDP_HOME}/jetty-base

ADD jetty-dist/dist          ${JETTY_HOME}

EXPOSE 443 8443 80

VOLUME ["${IDP_HOME}"]

WORKDIR ${JETTY_BASE}
CMD ["java",\
    "-Didp.home=/opt/shibboleth-idp", \
    "-Djetty.base=/opt/shibboleth-idp/jetty-base",\
    "-Djetty.logs=/opt/shibboleth-idp/jetty-base/logs",\
    "-jar", "/opt/jetty/start.jar"]
