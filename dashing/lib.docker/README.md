#A Docker API based implementation

Initially the idea of the project was about using Docker Api for retrieving all the monitoring data.
But once we started to use it in production, we found that we have multiple docker hosts (in different DCs)
and we want to observe all of our containers (for a specific app) on the same monitor.

So, the project was refactored to use ELK (ElasticSearch + LogStash) storage as a logs backend.
Old docker-related libs can be found under `lib.docker` folder (might be slightly damaged by refactoring).

In other words, `code in this folder isn't supported`. Use it as an academical stuff :)


### Dependencies
Integration with Docker API is based on https://github.com/swipely/docker-api


#### Installation
In addition to the main installation process, don't forget about the following:

0. You have to have docker and ruby installed locally: `apt-get install docker ruby`
1. The following gems are required: `gem install dashing docker docker-api`


#### Running as a Docker container
The container must be launched with `-v /var/run/docker.sock:/tmp/docker.sock`
mount (assuming that the docker instance on the host machine uses this socket).
We need that to request docker's API.

Important, the docker socket must not be mount under `var` directory: https://github.com/docker/docker/issues/5125
