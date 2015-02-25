#
# idp-builder dockerfile
#

#
# Base everything on the Oracle Java 8 JDK. Note that this
# does *not* incorporate the Unimited Strength Jurisdiction
# Policy Files, which are required for things like AES-256.
#
FROM dockerfile/java:oracle-java8

MAINTAINER Ian Young <ian@iay.org.uk>

ENV JETTY_HOME=/opt/jetty
ENV IDP_HOME=/opt/shibboleth-idp
ENV JETTY_BASE=${IDP_HOME}/jetty-base

#
# Unlimited Strength Jurisdiction Policy Files
#
# Step 1: test whether the policies are in effect (expect no).
#
WORKDIR /data
ADD Test.java /data/Test.java
RUN javac Test.java && java Test && rm Test.class

#
# Step 2: Apply the policy files by overwriting the default files.
#
ADD UnlimitedJCEPolicyJDK8/local_policy.jar ${JAVA_HOME}/jre/lib/security/
ADD UnlimitedJCEPolicyJDK8/US_export_policy.jar ${JAVA_HOME}/jre/lib/security/

#
# Step 3: re-test whether the policies are in effect.
#
RUN javac Test.java && java Test && rm Test.class

ADD jetty-dist/dist          ${JETTY_HOME}

EXPOSE 443 8443 80

VOLUME ["${IDP_HOME}"]

WORKDIR ${JETTY_BASE}
CMD ["java",\
    "-Didp.home=/opt/shibboleth-idp", \
    "-Djetty.base=/opt/shibboleth-idp/jetty-base",\
    "-Djetty.logs=/opt/shibboleth-idp/jetty-base/logs",\
    "-jar", "/opt/jetty/start.jar"]
