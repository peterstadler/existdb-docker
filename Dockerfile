# Dockerfile for running the WeGA-WebApp (https://github.com/Edirom/WeGA-WebApp) 
#
# initially based on https://github.com/jurrian/existdb-alpine

FROM openjdk:8-jre-slim
MAINTAINER Peter Stadler
LABEL org.opencontainers.image.source=https://github.com/peterstadler/existdb-docker

ARG VERSION
ARG MAX_MEMORY
ARG EXIST_URL
ARG SAXON_JAR
ARG XAR_REPO_URL
ARG XAR_NAMES

ENV VERSION ${VERSION:-6.0.0}
ENV EXIST_URL ${EXIST_URL:-https://github.com/eXist-db/exist/releases/download/eXist-${VERSION}/exist-installer-${VERSION}.jar}
ENV EXIST_HOME /opt/exist
ENV MAX_MEMORY ${MAX_MEMORY:-2048}
ENV EXIST_ENV ${EXIST_ENV:-development}
ENV EXIST_CONTEXT_PATH ${EXIST_CONTEXT_PATH:-/exist}
ENV EXIST_DATA_DIR ${EXIST_DATA_DIR:-/opt/exist/data}
ENV SAXON_JAR ${SAXON_JAR:-/opt/exist/lib/Saxon-HE-9.9.1-8.jar}
ENV LOG4J_FORMAT_MSG_NO_LOOKUPS true
ENV XAR_REPO_URL ${XAR_REPO_URL}
ENV XAR_NAMES ${XAR_NAMES}

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN useradd wegajetty

WORKDIR ${EXIST_HOME}

# adding expath packages to the autodeploy directory
COPY update-xars.sh /tmp/update-xars.sh
RUN chmod +x /tmp/update-xars.sh
RUN /tmp/update-xars.sh -v ${VERSION} -d ${EXIST_HOME}/autodeploy/ -r ${XAR_REPO_URL} -x "${XAR_NAMES}" -p
#COPY *.xar ${EXIST_HOME}/autodeploy/

# adding the entrypoint script
COPY entrypoint.sh ${EXIST_HOME}/

# adding some scripts/configuration files for fine tuning
COPY adjust-conf-files.xsl ${EXIST_HOME}/
COPY log4j2.xml ${EXIST_HOME}/ 

# main installation put into one RUN to squeeze image size
RUN apt-get update \
    && apt-get install -y curl pwgen zip \
    && echo "INSTALL_PATH=${EXIST_HOME}" > "/tmp/options.txt" \
    && echo "MAX_MEMORY=${MAX_MEMORY}" >> "/tmp/options.txt" \
    && echo "dataDir=${EXIST_DATA_DIR}" >> "/tmp/options.txt" \
    # install eXist-db
    # ending with true because java somehow returns with a non-zero after succesfull installing
    && curl -sL ${EXIST_URL} -o /tmp/exist.jar \
    && java -jar "/tmp/exist.jar" -options "/tmp/options.txt" || true \ 
    && rm -fr "/tmp/exist.jar" "/tmp/options.txt" ${EXIST_DATA_DIR}/* \
    # prefix java command with exec to force java being process 1 and receiving docker signals
    && sed -i 's/^${JAVA_RUN/exec ${JAVA_RUN/'  ${EXIST_HOME}/bin/startup.sh \
    # clean up apt cache 
    && rm -rf /var/lib/apt/lists/* \
    # remove portal webapp
    && rm -Rf ${EXIST_HOME}/etc/jetty/webapps/portal \
    # set permissions for the wegajetty user
    && chown -R wegajetty:wegajetty ${EXIST_HOME} \
    && chmod 755 ${EXIST_HOME}/entrypoint.sh \
    # remove JndiLookup class due to Log4Shell CVE-2021-44228 vulnerability
    && find ${EXIST_HOME} -name log4j-core-*.jar -exec zip -q -d {} org/apache/logging/log4j/core/lookup/JndiLookup.class \;


# switching to user wegajetty for further copying 
# and running exist-db 
USER wegajetty:wegajetty

VOLUME ["${EXIST_DATA_DIR}"]

HEALTHCHECK --interval=60s --timeout=5s \
  CMD curl -Lf http://localhost:8080${EXIST_CONTEXT_PATH} || exit 1

CMD ["./entrypoint.sh"]

EXPOSE 8080
