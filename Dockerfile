#
# idp-builder dockerfile
#

#
# Base everything on my Oracle Java 8 JDK container, which
# incorporates the Unlimited Strength Jurisdiction Policy Files
# required for things like AES-256.
#
FROM iay/java:oracle-8

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
