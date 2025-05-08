# existdb-docker
This is an [eXist DB](http://exist-db.org/) [docker](https://www.docker.com/)
image built on top of an eclipse-temurin:17-jre image.

# About this image
This image is inspired by [davidgaya/docker-eXistDB](https://github.com/davidgaya/docker-eXistDB) 
but adds adjustments to configuration files for development and production purposes.

Second, it is designed to work with TEI files in general—and with the [WeGA-WebApp](https://github.com/Edirom/WeGA-WebApp) in 
particular—so the default settings in eXist's `conf.xml` for whitespace handling and serialization reflect this. 

# How to build
Navigate into the root directory of this repository and enter:
```shell
docker build -t existdb --build-arg VERSION=6.4.0 .
```

## available parameters
* **VERSION**: The eXist version to use. Defaults to 6.4.0 

# How to run
```shell
docker run --rm -it \
    -p 8080:8080 \
    --name existdb \
    -v /your/path/to/exist-data:/opt/exist/data \
    -v /your/path/to/exist-logs:/opt/exist/logs \
    -e EXIST_ENV=development \
    -e EXIST_CONTEXT_PATH=/exist \    
    stadlerpeter/existdb:latest    
```

## available parameters
* **EXIST_ENV**: This will toggle the modification of configuration files. 
    A value of "production" will remove most servlets and will deny direct 
    access to the REST interface. Default is "development" which will not 
    alter  
* **EXIST_CONTEXT_PATH**: The eXist context path. Defaults to `/exist`, 
    which means you'll find eXist at `http://localhost:8080/exist/` but you 
    may change this to simply `/` and your default app will repond at `http://localhost:8080/`
*  **EXIST_DEFAULT_APP_PATH**: the database path to your default app, e.g. `xmldb:exist:///db/apps/WeGA-WebApp`.
    This default app will respond directly at the `$EXIST_CONTEXT_PATH` (while all other apps are still 
    available at `/apps/`).

## passing JVM flags to the container

Use the `JAVA_TOOL_OPTIONS` parameter to pass any JVM flags to the 
container. E.g.
```shell
JAVA_TOOL_OPTIONS: -XX:MaxRAMPercentage=75.0
```
This will set the max heap size to 75% of the memory allocated to the Docker 
container.  

## setting the admin password
The admin password can be supplied via the `$EXIST_PASSWORD` environment variable or the equivalent Docker secret `$EXIST_PASSWORD_FILE`. 
If none of these variables are set (or both contain empty values) a random password will be generated and echoed to the logs.  

```yaml
# docker-compose.yml
version: "3.6"
services:
  existdb:
    image: stadlerpeter/existdb:latest
    ports: 
      - 8080:8080
    environment: 
      - EXIST_PASSWORD_FILE=/run/secrets/existdb_passwd
    restart: unless-stopped
    secrets:
      - source: existdb_passwd
    volumes:
      - existdb_data:/opt/exist/data
secrets:
  existdb_passwd:
    file: /local/path/to/password-file
volumes:
  existdb_data:
```  

# License
This Dockerfile is licensed under a MIT license.

eXist is licensed under the GNU Lesser General Public License v2.1.
