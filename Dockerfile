FROM ubuntu:14.04
MAINTAINER Mikhail Krestjaninoff <mikhail.krestjaninoff@gmail.com>

RUN apt-get update && apt-get install -y \
  build-essential \
  ruby1.9.1 \
  ruby1.9.1-dev \
  nodejs

RUN gem install \
  dashing \
  bundler \
  docker \
  docker-api

COPY dashing /docker-monitor
WORKDIR /docker-monitor

EXPOSE 3030

ENTRYPOINT ["dashing"]
CMD ["start"]
