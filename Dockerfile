# Dockerfile for running the WeGA-WebApp (https://github.com/Edirom/WeGA-WebApp) 
#
# adjusted from https://github.com/jurrian/existdb-alpine

FROM openjdk:8-jre-alpine
MAINTAINER Peter Stadler

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN addgroup -S wegajetty \
    && adduser -D -S -H -G wegajetty wegajetty \
    && rm -rf /etc/group- /etc/passwd- /etc/shadow-

ARG VERSION
ARG MAX_MEMORY

ENV VERSION ${VERSION:-4.7.1}
ENV EXIST_URL https://dl.bintray.com/existdb/releases/eXist-db-setup-${VERSION}.jar
ENV EXIST_HOME /opt/exist
ENV MAX_MEMORY ${MAX_MEMORY:-2048}
ENV EXIST_ENV ${EXIST_ENV:-development}
ENV EXIST_CONTEXT_PATH ${EXIST_CONTEXT_PATH:-/exist}

WORKDIR ${EXIST_HOME}

# download eXist
ADD ${EXIST_URL} /tmp/exist.jar
#COPY *.jar /tmp/exist.jar

RUN apk --update add bash pwgen curl \
    && echo "INSTALL_PATH=${EXIST_HOME}" > "/tmp/options.txt" \
    && echo "MAX_MEMORY=${MAX_MEMORY}" >> "/tmp/options.txt" \
    # install eXist-db
    # ending with true because java somehow returns with a non-zero after succesfull installing
    && java -jar "/tmp/exist.jar" -options "/tmp/options.txt" || true \ 
    && rm -f "/tmp/exist.jar" "/tmp/options.txt" \
    # prefix java command with exec to force java being process 1 and receiving docker signals
    && sed -i 's/^${JAVA_RUN/exec ${JAVA_RUN/'  ${EXIST_HOME}/bin/startup.sh \
    # alpine has no locale binary, this will fix that
    && printf "#!/bin/sh\necho $LANG" > /usr/bin/locale \
    && chmod +x /usr/bin/locale \
    # remove portal webapp
    && rm -Rf ${EXIST_HOME}/tools/jetty/webapps/portal

# adding expath packages to the autodeploy directory
ADD http://exist-db.org/exist/apps/public-repo/public/functx-1.0.xar ${EXIST_HOME}/autodeploy/ 
#COPY *.xar ${EXIST_HOME}/autodeploy/

# adding the entrypoint script
COPY entrypoint.sh ${EXIST_HOME}/

# adding some scripts/configuration files for fine tuning
COPY adjust-conf-files.xsl ${EXIST_HOME}/
COPY log4j2.xml ${EXIST_HOME}/ 

# set permissions for the wegajetty user
RUN chown -R wegajetty:wegajetty ${EXIST_HOME} \
    && chmod 755 ${EXIST_HOME}/entrypoint.sh

# switching to user wegajetty for further copying 
# and running exist-db 
USER wegajetty:wegajetty

VOLUME ["${EXIST_HOME}/webapp/WEB-INF/data","${EXIST_HOME}/webapp/WEB-INF/logs","${EXIST_HOME}/tools/jetty/logs"]


HEALTHCHECK --interval=60s --timeout=5s \
  CMD curl -Lf http://localhost:8080${EXIST_CONTEXT_PATH} || exit 1

CMD ["./entrypoint.sh"]

EXPOSE 8080
