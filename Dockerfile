#
# Simple puppet server image using stock Debian Jessie packages (3.7.2)
#

FROM debian:jessie
MAINTAINER jkrauska@gmail.com

LABEL Description="This image uses stock debian8 packages to create a passanager based puppet server."

ENV HOME /root
ARG DEBIAN_FRONTEND=noninteractive

# Helper package
RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils \
    && rm -rf /var/lib/apt/lists/*

# Create static gid/uid for puppet
# (nice to have to match on host OS filesystem)
RUN groupadd -r -g 501 puppet && \
      useradd -u 501 -r -g puppet puppet

# Install puppet related packages - part 1
RUN apt-get update && \
    apt-get install  -y \
      puppet-common \
      puppetmaster-common \
      && rm -rf /var/lib/apt/lists/*

# part 2
RUN apt-get update && \
    apt-get install  -y \
    puppetmaster-passenger \
    puppet-lint \
    && rm -rf /var/lib/apt/lists/*

# FIXME: remove random certs generated at install??
# (they are referenced in apache config..)

# Add-on eyaml package for encrypted yaml
RUN gem install hiera-eyaml

# Basic tools for edits and git taagging 
RUN apt-get update && \
    apt-get install  -y \
    git \
    lsof \
    vim \
    wget \
    && rm -rf /var/lib/apt/lists/*

################################
# puppetdb
RUN apt-get update && \
    apt-get install  -y \
        default-jre-headless \
	&& rm -rf /var/lib/apt/lists/*

RUN wget http://apt.puppetlabs.com/pool/wheezy/PC1/p/puppetdb/puppetdb_2.3.8-1puppetlabs1_all.deb
RUN dpkg -i puppetdb_2.3.8-1puppetlabs1_all.deb


# Docker-ception (include Dockerfile used for build in an obvious spot)
ADD Dockerfile /root/docker.info/Dockerfile

# Puppet port
EXPOSE 8140

# Mutable directories
VOLUME ["/etc/puppet", "/var/lib/puppet","/var/log/apache2"]

RUN chown puppet:puppet /etc/puppet /var/lib/puppet /var/log/puppet
 	
# FIXME:
# Debug logging can be turned on by editig:
#     /usr/share/puppet/rack/puppetmasterd/config.ru
# ARGV << "--debug"
# ARGV << "--logdest" << "/var/lib/puppet/log/puppet-master.log"

# Start apache2/passanger and tail logs
CMD /etc/init.d/apache2 start && \
    sleep 5 && \
    tail -F /var/log/apache2/*.log
