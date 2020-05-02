#!/bin/bash

SAXON="java ${JAVA_OPTIONS} -jar ${EXIST_HOME}/lib/endorsed/Saxon-HE-9.6.0-7.jar env=${EXIST_ENV} context_path=${EXIST_CONTEXT_PATH} default_app_path=${EXIST_DEFAULT_APP_PATH} -xsl:${EXIST_HOME}/adjust-conf-files.xsl"

# remove DTD reference since the URL is broken
sed -i 2d ${EXIST_HOME}/tools/jetty/webapps/exist-webapp-context.xml

# adjusting configuration files
${SAXON} -s:${EXIST_HOME}/conf.xml -o:/tmp/conf.xml 
${SAXON} -s:${EXIST_HOME}/tools/jetty/webapps/exist-webapp-context.xml -o:/tmp/exist-webapp-context.xml
${SAXON} -s:${EXIST_HOME}/webapp/WEB-INF/controller-config.xml -o:/tmp/controller-config.xml
${SAXON} -s:${EXIST_HOME}/webapp/WEB-INF/web.xml -o:/tmp/web.xml
${SAXON} -s:${EXIST_HOME}/log4j2.xml -o:/tmp/log4j2.xml

# copying modified configuration files from tmp folder to original destination
mv /tmp/conf.xml ${EXIST_HOME}/conf.xml
mv /tmp/exist-webapp-context.xml ${EXIST_HOME}/tools/jetty/webapps/exist-webapp-context.xml
mv /tmp/controller-config.xml ${EXIST_HOME}/webapp/WEB-INF/controller-config.xml
mv /tmp/web.xml ${EXIST_HOME}/webapp/WEB-INF/web.xml
mv /tmp/log4j2.xml ${EXIST_HOME}/log4j2.xml

# function for setting the existdb password
function set_passwd {
${EXIST_HOME}/bin/client.sh -l -s -u admin -P \$adminPasswd << EOF 
passwd admin
$1
$1
quit
EOF
echo "do not delete" > ${EXIST_HOME}/webapp/WEB-INF/data/secret_set
}

# try to read the admin password from '${EXIST_HOME}/webapp/WEB-INF/data/secret.txt' or generate a random one 
# setting ${EXIST_HOME}/webapp/WEB-INF/data/secret_set as a flag for a set password
if [ -s ${EXIST_HOME}/webapp/WEB-INF/data/secret.txt ] && [ -s ${EXIST_HOME}/webapp/WEB-INF/data/secret_set ]
then
    SECRET=`cat ${EXIST_HOME}/webapp/WEB-INF/data/secret.txt`
    echo "***********************************************************************"
    echo "password already set, see ${EXIST_HOME}/webapp/WEB-INF/data/secret.txt"
    echo "***********************************************************************"
elif [ -s ${EXIST_HOME}/webapp/WEB-INF/data/secret.txt ]
then
    # read the password from a file
    SECRET=`cat ${EXIST_HOME}/webapp/WEB-INF/data/secret.txt` 
    echo "********************************"
    echo "setting password to your secret"
    echo "********************************"
    # setting the eXistdb admin password
    set_passwd ${SECRET}
else 
    # generate a random password and output it to a file
    SECRET=`pwgen 24 -csn`
    echo ${SECRET} > ${EXIST_HOME}/webapp/WEB-INF/data/secret.txt
    echo "********************************"
    echo "setting password to ${SECRET}"
    echo "********************************"
    # setting the eXistdb admin password
    set_passwd ${SECRET}
fi

# starting the database
exec ${EXIST_HOME}/bin/startup.sh