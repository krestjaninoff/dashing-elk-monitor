FROM ubuntu:14.04
MAINTAINER Mikhail Krestjaninoff <mikhail.krestjaninoff@gmail.com>

# Proxy (note, you can't use localhost as proxy host because it references to the container)
ENV http_proxy http://172.25.62.101:3128
ENV https_proxy http://172.25.62.101:3128

RUN apt-get update && apt-get install -y \
  build-essential \
  ruby1.9.1 \
  ruby1.9.1-dev \
  nodejs

RUN gem install \
  dashing \
  bundler

COPY dashing /dashing-elk-monitor
WORKDIR /dashing-elk-monitor

EXPOSE 3030

ENTRYPOINT ["dashing"]
CMD ["start"]
