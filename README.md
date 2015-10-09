#Docker monitor extension for Dashing

Initially the idea of the project was about using Docker Api for retrieving all the monitoring data.
But once we started to use it in production, we found that we have multiple docker hosts (in different DCs)
and we want to observe all of our containers (for a specific app) on the same monitor.

So, the project was refactored to use ELK (ElasticSearch + LogStash) storage as a logs backend.
Old docker-related libs can be found under `lib.docker` folder (might be slightly damaged by refactoring).

Inspired by https://github.com/Shopify/dashing

### Installation
0. You have to have docker and ruby installed locally: `apt-get install ruby`
1. The following gems are required: `gem install dashing`
2. This project is a result of "dashing new" and "bundle" commands (so, you don't need to run them)
3. To run this project go to "dashing" directory and launch "dashing start" command


### Configuration
The list of monitored containers is combined with the layout file - `dashboards/dashboard.erb`.
For ElasticSearch settings see `lib/elk_monitor.rb`.


### Using with Docker API
Integration with Docker API is based on https://github.com/swipely/docker-api

#### Installation
0. You have to have docker and ruby installed locally: `apt-get install docker ruby`
1. The following gems are required: `gem install dashing docker docker-api`

#### Running as a Docker container
The container must be launched with `-v /var/run/docker.sock:/tmp/docker.sock`
mount (assuming that the docker instance on the host machine uses this socket).
We need that to request docker's API.

Important, the docker socket must not be mount under `var` directory: https://github.com/docker/docker/issues/5125


### Building

  * Build the image: `docker build -t krestjaninoff/docker-monitor:0.0.1 .`
  * Push the image: `docker push krestjaninoff/docker-monitor:0.0.1 .`
  * Start the container: `docker run -d -v /path/to/dashboard.erb:/docker-monitor/dashboards/dashboard.erb -v /path/to/known.errors:/known.errors --memory=256m -p 3030:3030 --name docker-monitor krestjaninoff/docker-monitor:0.0.1`
  * Add the timezone, if necessary (-e "TZ=Europe/Moscow")
