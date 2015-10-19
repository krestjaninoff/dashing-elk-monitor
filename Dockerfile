FROM ubuntu:14.04
MAINTAINER Mikhail Krestjaninoff <mikhail.krestjaninoff@gmail.com>

# Proxy (note, you can't use localhost as proxy host because it references to the container)
#ENV http_proxy http://127.0.0.1:3128
#ENV https_proxy http://127.0.0.1:3128

RUN apt-get update && apt-get install -y \
  build-essential \
  ruby1.9.1 \
  ruby1.9.1-dev \
  nodejs \
  curl

RUN gem install \
  dashing \
  bundler \
  json \
  docker

COPY dashing /dashing-elk-monitor

WORKDIR /dashing-elk-monitor/dasing
RUN bundle install

#ENV http_proxy ""
#ENV https_proxy ""

WORKDIR /dashing-elk-monitor
EXPOSE 3030

ENTRYPOINT ["dashing"]
CMD ["start"]
