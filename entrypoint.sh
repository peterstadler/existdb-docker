#!/bin/bash

SAXON="java ${JAVA_OPTIONS} -cp ${SAXON_JAR}:${EXIST_HOME}/lib/xml-resolver-1.2.jar net.sf.saxon.Transform  env=${EXIST_ENV} context_path=${EXIST_CONTEXT_PATH} default_app_path=${EXIST_DEFAULT_APP_PATH} -xsl:${EXIST_HOME}/adjust-conf-files.xsl -catalog:${EXIST_HOME}/catalog.xml"

##############################################
# function for adjusting configuration files for eXist versions >= 5
##############################################
function adjust_config_files_eXist5 {
# replace http DTD references with https
# this should be obsolete since eXist versions 4.11.0/5.5.0 but is left here for older versions
# see https://github.com/eXist-db/exist/pull/4616
grep -rl "http://www.eclipse.org/jetty/configure_9_3.dtd" . | xargs sed -i 's+http://www.eclipse.org/jetty/configure_9_3.dtd+https://www.eclipse.org/jetty/configure_9_3.dtd+g' 

${SAXON} -s:${EXIST_HOME}/etc/conf.xml -o:/tmp/conf.xml 
${SAXON} -s:${EXIST_HOME}/etc/jetty/webapps/exist-webapp-context.xml -o:/tmp/exist-webapp-context.xml
${SAXON} -s:${EXIST_HOME}/etc/webapp/WEB-INF/controller-config.xml -o:/tmp/controller-config.xml
${SAXON} -s:${EXIST_HOME}/etc/webapp/WEB-INF/web.xml -o:/tmp/web.xml
${SAXON} -s:${EXIST_HOME}/etc/log4j2.xml -o:/tmp/log4j2.xml
${SAXON} -s:${EXIST_HOME}/etc/jetty/jetty.xml -o:/tmp/jetty.xml

# copying modified configuration files from tmp folder to original destination
mv /tmp/conf.xml ${EXIST_HOME}/etc/conf.xml
mv /tmp/exist-webapp-context.xml ${EXIST_HOME}/etc/jetty/webapps/exist-webapp-context.xml
mv /tmp/controller-config.xml ${EXIST_HOME}/etc/webapp/WEB-INF/controller-config.xml
mv /tmp/web.xml ${EXIST_HOME}/etc/webapp/WEB-INF/web.xml
mv /tmp/log4j2.xml ${EXIST_HOME}/etc/log4j2.xml
mv /tmp/jetty.xml ${EXIST_HOME}/etc/jetty/jetty.xml
}

##############################################
# function for adjusting configuration files for eXist versions < 5
##############################################
function adjust_config_files_eXist4 {
# replace http DTD references with https
# this should be obsolete since eXist versions 4.11.0/5.5.0 but is left here for older versions
# see https://github.com/eXist-db/exist/pull/4616
grep -rl "http://www.eclipse.org/jetty/configure_9_3.dtd" . | xargs sed -i 's+http://www.eclipse.org/jetty/configure_9_3.dtd+https://www.eclipse.org/jetty/configure_9_3.dtd+g'

# adjusting configuration files
${SAXON} -s:${EXIST_HOME}/conf.xml -o:/tmp/conf.xml 
${SAXON} -s:${EXIST_HOME}/tools/jetty/webapps/exist-webapp-context.xml -o:/tmp/exist-webapp-context.xml
${SAXON} -s:${EXIST_HOME}/webapp/WEB-INF/controller-config.xml -o:/tmp/controller-config.xml
${SAXON} -s:${EXIST_HOME}/webapp/WEB-INF/web.xml -o:/tmp/web.xml
${SAXON} -s:${EXIST_HOME}/log4j2.xml -o:/tmp/log4j2.xml

# patch bin/functions.d/getopt-settings.sh
patch --silent ${EXIST_HOME}/bin/functions.d/getopt-settings.sh ${EXIST_HOME}/getopt-settings.eXist4.patch

# copying modified configuration files from tmp folder to original destination
mv /tmp/conf.xml ${EXIST_HOME}/conf.xml
mv /tmp/exist-webapp-context.xml ${EXIST_HOME}/tools/jetty/webapps/exist-webapp-context.xml
mv /tmp/controller-config.xml ${EXIST_HOME}/webapp/WEB-INF/controller-config.xml
mv /tmp/web.xml ${EXIST_HOME}/webapp/WEB-INF/web.xml
mv /tmp/log4j2.xml ${EXIST_HOME}/log4j2.xml
}

##############################################
# function for setting the exist password
##############################################
function set_passwd {
${EXIST_HOME}/bin/client.sh -l -s -u admin -P "" << EOF 
passwd admin
$1
$1
quit
EOF
echo "do not delete" > ${EXIST_DATA_DIR}/.docker_secret
}

if [[ ${VERSION} > 5 || ${VERSION} = 5 ]]
then
    adjust_config_files_eXist5
else
    adjust_config_files_eXist4 
fi

# now we are setting the admin password
# if the magic file ${EXIST_DATA_DIR}/.docker_secret exists
# we won't take any action because the password is already set
if [[ -s ${EXIST_DATA_DIR}/.docker_secret ]]
then 
    echo "********************"
    echo "password already set"
    echo "********************"

# next, try to read the admin password from Docker secrets 
# if the ${EXIST_PASSWORD_FILE} environment variable is set. 
elif [[ -s ${EXIST_PASSWORD_FILE} ]] 
then
    SECRET=`cat ${EXIST_PASSWORD_FILE}`
    echo "************************************"
    echo "setting password from Docker secrets"
    echo "************************************"
    # setting the eXist admin password
    set_passwd ${SECRET}

# next, look for the ${EXIST_PASSWORD} environment variable 
# to set the password 
elif [[ ${EXIST_PASSWORD} ]] && ! [[ -s ${EXIST_DATA_DIR}/.docker_secret ]]
then
    # read the password from the environment variable ${EXIST_PASSWORD}
    echo "*************************************************"
    echo "setting password from Docker environment variable"
    echo "NB: this is less secure than via Docker secrets"
    echo "*************************************************"
    # setting the eXist admin password
    set_passwd ${EXIST_PASSWORD}

# finally fallback to generating a random password
else
    # generate a random password and output it to the logs
    SECRET=`pwgen 24 -csn`
    echo "********************************"
    echo "no admin password provided"
    echo "setting password to ${SECRET}"
    echo "********************************"
    # setting the eXist admin password
    set_passwd ${SECRET}
fi

# starting the database
exec ${EXIST_HOME}/bin/startup.sh