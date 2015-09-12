###Docker monitor extension for Dashing

The project is under construction.

Inspired by https://github.com/swipely/docker-api and https://github.com/Shopify/dashing

### Installation
0. You have to have docker and ruby installed locally: apt-get install docker ruby
1. The following gems are required: gem install dashing docker docker-api
2. This project is a result of "dashing new" and "bundle" commands
3. To run this project use "dashing start" command


### Configuration
At the moment you have to configure your containers in both dashboards/docker.erb
and lib/docker-api-client.rb. That will be fixed one day.
