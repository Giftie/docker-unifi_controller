#docker run -d -p 2222:22 -p 8080:8080 -p 8443:8443 -p 37117:27117 -v /mnt/cache/appdata/unifi/data:/usr/lib/unifi/data --name unifi rednut/unifi-controller

# build docker image to run the unifi controller
#
# the unifi contoller is used to admin ubunquty wifi access points
#
FROM phusion/baseimage:0.9.11
MAINTAINER giftie giftie61@hotmail.com

ENV DEBIAN_FRONTEND noninteractive

RUN usermod -u 99 nobody
RUN usermod -g 100 nobody

# this forces dpkg not to call sync() after package extraction and speeds up install
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup
# we don't need and apt cache in a container
RUN echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache

RUN mkdir -p /var/log/supervisor /usr/lib/unifi/data && touch /usr/lib/unifi/data/.unifidatadir

RUN apt-get update -q -y
RUN apt-get install -q -y supervisor apt-utils lsb-release curl wget rsync

# add ubiquity repo + key
RUN echo "deb http://www.ubnt.com/downloads/unifi/distros/deb/ubuntu ubuntu ubiquiti" > /etc/apt/sources.list.d/ubiquity.list && \
   apt-key adv --keyserver keyserver.ubuntu.com --recv C0A52C50 && apt-get update -q -y && apt-get install -q -y unifi-beta

ADD ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

VOLUME /usr/lib/unifi/data
EXPOSE 8443 8080 27117
WORKDIR /usr/lib/unifi
CMD ["/usr/bin/supervisord"]