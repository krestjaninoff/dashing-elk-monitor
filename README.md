###Docker monitor extension for Dashing

The project is under construction.

Inspired by https://github.com/swipely/docker-api and https://github.com/Shopify/dashing

### Installation
0. You have to have docker and ruby installed locally: apt-get install docker ruby
1. The following gems are required: gem install dashing docker docker-api
2. This project is a result of "dashing new" and "bundle" commands (so, you don't need to run them)
3. To run this project go to "dashing" directory and launch "dashing start" command

### Configuration
At the moment you have to configure your containers in both dashboards/docker.erb
and lib/docker-api-client.rb (under "dashing" dir). That will be fixed one day.

### Running as a Docker container
The container must be launched with `-v /var/run/docker.sock:/var/run/docker.sock --privileged
mount (assuming that the docker instance on the host machine uses this socket).
We need that to request docker's API.

### Building
* Build the image: `docker build -t krestjaninoff/docker-monitor:0.0.1 .`
* Start the container: `docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 8080:3030 --privileged --name docker-monitor krestjaninoff/docker-monitor:0.0.1`
