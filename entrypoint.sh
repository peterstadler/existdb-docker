#!/bin/bash

SAXON="java ${JAVA_OPTIONS} -jar /usr/share/java/saxon/saxon9he.jar env=${EXIST_ENV} context_path=${EXIST_CONTEXT_PATH} -xsl:${EXIST_HOME}/adjust-conf-files.xsl"

# try to read the admin password from 'secret.txt' or generate a random one 
if [ -s ${EXIST_HOME}/secret.txt ]
then
    SECRET=`cat ${EXIST_HOME}/secret.txt`
else 
    # generate a random password and output it to a file
    SECRET=`pwgen 12 -y`
    echo ${SECRET} > ${EXIST_HOME}/secret.txt
fi

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

# setting the eXistdb admin password
/opt/exist/bin/client.sh -l -s -u admin -P \$adminPasswd << EOF 
passwd admin
${SECRET}
${SECRET}
quit
EOF

# starting the database
exec ${EXIST_HOME}/bin/startup.sh