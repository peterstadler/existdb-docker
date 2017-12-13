# existdb-docker
This is an [eXist DB](http://exist-db.org/) [docker](https://www.docker.com/) image build on top of an official java-alpine image.

# About this image
This image is inspired by [davidgaya/docker-eXistDB](https://github.com/davidgaya/docker-eXistDB) 
but adds adjustments to configuration files for development and production purposes.

Second, it is designed to work with TEI files in general—and with the [WeGA-WebApp](https://github.com/Edirom/WeGA-WebApp) in 
particular—so the default settings in eXist's `conf.xml` for whitespace and serialization reflect this. 

# How to build
Navigate into the root directory of this repository and enter:
```
docker build -t existdb .
```

# How to run
```
docker run --rm -it \
    -p 8080:8080 \
    --name existdb \
    -v /your/path/to/exist-data:/opt/exist/webapp/WEB-INF/data \
    -v /your/path/to/exist-logs:/opt/exist/webapp/WEB-INF/logs \
    -e EXIST_ENV=development \
    -e EXIST_CONTEXT_PATH=/exist \    
    stadlerpeter/existdb:latest    
```

## available parameters
* **EXIST_ENV**: this will toggle the modification of configuration files. 
    A value of "production" will remove most servlets and will deny direct 
    access to the REST interface. Default is "development" which will not 
    alter  
* **EXIST_CONTEXT_PATH**: 

# License
This Dockerfile is licensed under a MIT license.

eXist is licensed under the GNU Lesser General Public License v2.1.