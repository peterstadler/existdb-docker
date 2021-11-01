# Dockerfile for running the WeGA-WebApp (https://github.com/Edirom/WeGA-WebApp) 
#
# adjusted from https://github.com/jurrian/existdb-alpine

FROM openjdk:8-jre-alpine
MAINTAINER Peter Stadler
LABEL org.opencontainers.image.source=https://github.com/peterstadler/existdb-docker

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN addgroup -S wegajetty \
    && adduser -D -S -H -G wegajetty wegajetty \
    && rm -rf /etc/group- /etc/passwd- /etc/shadow-

ARG VERSION
ARG MAX_MEMORY
ARG EXIST_URL
ARG SAXON_JAR
ARG XAR_REPO_URL
ARG UPDATE_XARS
ARG XAR_REPO_URL

ENV VERSION ${VERSION:-5.3.0}
ENV EXIST_URL ${EXIST_URL:-https://github.com/eXist-db/exist/releases/download/eXist-${VERSION}/exist-installer-${VERSION}.jar}
ENV EXIST_HOME /opt/exist
ENV MAX_MEMORY ${MAX_MEMORY:-2048}
ENV EXIST_ENV ${EXIST_ENV:-development}
ENV EXIST_CONTEXT_PATH ${EXIST_CONTEXT_PATH:-/exist}
ENV EXIST_DATA_DIR ${EXIST_DATA_DIR:-/opt/exist/data}
ENV SAXON_JAR ${SAXON_JAR:-/opt/exist/lib/Saxon-HE-9.9.1-7.jar}
ENV XAR_REPO_URL ${XAR_REPO_URL:-https://exist-db.org/exist/apps/public-repo/public}
ENV UPDATE_XARS ${UPDATE_XARS:-false}
ENV XAR_REPO_URL ${XAR_REPO_URL:+-r ${XAR_REPO_URL}}
ENV XAR_NAMES ${XAR_NAMES:+-x ${XAR_NAMES}}

WORKDIR ${EXIST_HOME}

# download eXist
ADD ${EXIST_URL} /tmp/exist.jar
#COPY *.jar /tmp/exist.jar

RUN apk --update add bash pwgen curl libxml2-utils \
    && echo "INSTALL_PATH=${EXIST_HOME}" > "/tmp/options.txt" \
    && echo "MAX_MEMORY=${MAX_MEMORY}" >> "/tmp/options.txt" \
    && echo "dataDir=${EXIST_DATA_DIR}" >> "/tmp/options.txt" \
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
    && rm -Rf ${EXIST_HOME}/etc/jetty/webapps/portal

# adding expath packages to the autodeploy directory
COPY update-xars.sh /tmp/update-xars.sh
RUN chmod +x /tmp/update-xars.sh
RUN /tmp/update-xars.sh ${VERSION} ${XAR_REPO_URL}
#COPY *.xar ${EXIST_HOME}/autodeploy/

# adding the entrypoint script
COPY entrypoint.sh ${EXIST_HOME}/

# adding some scripts/configuration files for fine tuning
COPY adjust-conf-files.xsl ${EXIST_HOME}/
COPY log4j2.xml ${EXIST_HOME}/ 

# set permissions for the wegajetty user
RUN rm -Rf ${EXIST_DATA_DIR}/* \
    && chown -R wegajetty:wegajetty ${EXIST_HOME} \
    && chmod 755 ${EXIST_HOME}/entrypoint.sh

# switching to user wegajetty for further copying 
# and running exist-db 
USER wegajetty:wegajetty

VOLUME ["${EXIST_DATA_DIR}"]

HEALTHCHECK --interval=60s --timeout=5s \
  CMD curl -Lf http://localhost:8080${EXIST_CONTEXT_PATH} || exit 1

CMD ["./entrypoint.sh"]

EXPOSE 8080
