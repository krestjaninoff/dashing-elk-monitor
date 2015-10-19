#A Dashing extension for ELK-based microservices monitoring

This is a simple Dashing extension which allows you to visualize LogStash'ed logs
 of your application in a simple and very effective way:

![](http://trustmeiamadeveloper.com/content/images/2015/10/dasing_elk_monitoring_small.jpg)

It assumes that you use the default [LogStash appender](https://github.com/logstash/logstash-logback-encoder) for LogBack
 with the default LogStash mapping. Also, it wants you to add an additional field,
 which allows to distinguish one service from another - `app.id` (see `elk-client.rb` for ES query example).

You can use two different backends to persist and manage the list of known errors: a plain text file and Consul key/value
  storage. Why Consul? Just because we already have it in our infrastructure, it supports k/v and has a pretty UI (what is very important if you want your QA to manage the issues instead of you).

Inspired by https://github.com/Shopify/dashing


### Installation
The application can be assembled as a Docker container. But if you want to install it on your OS directly, do the following:

0. Install Ruby: `apt-get install ruby-1.9.1`
1. Add some gems: `gem install dashing`
2. This project is a result of "dashing new" and "bundle" commands (so, you don't need to run them)
3. Go to "dashing" directory and run "dashing start" command
4. ...
5. PROFIT!!!


### Configuration
The list of monitored services is combined with the layout file - `dashboards/dashboard.erb`.
In case of Docker container, this file can be mounted from an external source.

All other settings must be set up through ENV variables:

  * ELK_HOST - ElasticSearch host ('elk-host.com')
  * ELK_PORT - ElasticSearch port ('9200')
  * ELK_LOG_ACTUAL_TIME - Time period for analyzing ('60m')
  * DEM_ERRORS_SOURCE - Source of known errors, could be either 'file' or 'consul' (default is 'file')
  * CONSUL_KV_API - Consul key/value API url ('http://consul-host/v1/kv')
  * CONSUL_DC - Consul datacenter ('dc1')
  * CONSUL_ERRORS_PATH - Path to errors in Consul storage ('path/to/errors')


### Building

  * Build the image: `docker build -t krestjaninoff/dashing-elk-monitor:latest .`
  * Push the image: `docker push krestjaninoff/dashing-elk-monitor:latest .`

To start the container use the following command:

```bash
docker run -d \
    -v /path/to/dashboard.erb:/dashing-elk-monitor/dashboards/dashboard.erb \
    -v /path/to/known.errors:/known.errors \
      \
    -e ELK_HOST=elk-host.com \
    -e ELK_PORT=9200 \
    -e ELK_LOG_ACTUAL_TIME=60m \
    -e DEM_ERRORS_SOURCE=file \
    -e CONSUL_KV_API=http://consul-host/v1/kv \
    -e CONSUL_DC=dc1 \
    -e CONSUL_ERRORS_PATH=path/to/errors \
      \
    --memory=256m \
    -p 3030:3030 \
      \
    --name dashing-elk-monitor \
    krestjaninoff/dashing-elk-monitor:latest
```

Add the timezone, if necessary (-e "TZ=Europe/Moscow")
