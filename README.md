###Docker monitor extension for Dashing

**The project is under construction**.

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
The container must be launched with `-v /var/run/docker.sock:/tmp/docker.sock`
mount (assuming that the docker instance on the host machine uses this socket).
We need that to request docker's API.

Important, the docker socket must not be mount under `var` directory: https://github.com/docker/docker/issues/5125

### Building

  * Build the image: `docker build -t krestjaninoff/docker-monitor:0.0.1 .`
  * Push the image: `docker push krestjaninoff/docker-monitor:0.0.1 .`
  * Start the container: `docker run -d -v /path/to/dashboard.erb:/docker-monitor/dashboards/dashboard.erb -v /path/to/known.errors:/known.errors -v /var/run/docker.sock:/tmp/docker.sock --memory=256m -p 3030:3030 --name docker-monitor krestjaninoff/docker-monitor:0.0.1`
  * Add the timezone if necessary (-e "TZ=Europe/Moscow")
