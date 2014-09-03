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

RUN mkdir -p /usr/lib/unifi/data && touch /usr/lib/unifi/data/.unifidatadir

RUN apt-get update -q -y
RUN apt-get install -q -y apt-utils lsb-release curl wget rsync iptables iptables-persistent
RUN apt-get update

#modify iptables
# SSH
RUN iptables -A INPUT -p tcp -m tcp -m state --dport 22 --state NEW -j ACCEPT
# Unifi - Device Inform & Management
RUN iptables -A INPUT -p tcp -m tcp -m state --dport 8080:8081 --state NEW -j ACCEPT
# Unifi - HTTPS Management
RUN iptables -A INPUT -p tcp -m tcp -m state --dport 8443 --state NEW -j ACCEPT
# Unifi - Guest Portal Redirect (SSL)
RUN iptables -A INPUT -p tcp -m tcp -m state --dport 8843 --state NEW -j ACCEPT
# Unifi - Guest Portal Redirect
RUN iptables -A INPUT -p tcp -m tcp -m state --dport 8880 --state NEW -j ACCEPT
# Webmin
RUN iptables -A INPUT -p tcp -m tcp -m state --dport 10000:10010 --state NEW -j ACCEPT
# Ubiquiti AP Discovery
RUN iptables -A INPUT -p udp -m udp --dport 10001 --sport 10001 -j ACCEPT
RUN iptables -A INPUT -j DROP

# add ubiquity repo + key
RUN echo "deb http://www.ubnt.com/downloads/unifi/distros/deb/ubuntu ubuntu ubiquiti" > /etc/apt/sources.list.d/ubiquity.list && \
   apt-key adv --keyserver keyserver.ubuntu.com --recv C0A52C50 && apt-get update -q -y && apt-get install -q -y unifi-rapid
   
VOLUME /usr/lib/unifi/data
EXPOSE  3478 8080 8081 8443 8843 8880 10001 27117 
WORKDIR /usr/lib/unifi

CMD ["/usr/lib/jvm/java-6-openjdk-amd64/jre/bin/java", "-Xmx1024M", "-jar", "/usr/lib/unifi/lib/ace.jar", "start"]
