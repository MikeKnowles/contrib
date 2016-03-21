FROM ubuntu:14.04
MAINTAINER Mike Knowles <mikewknowles+rods@gmail.com>

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV IRODS_VERSION 4.1.8
ARG ICAT_PLUGIN
ENV FTP_URL ftp://ftp.renci.org/pub/irods/releases/$IRODS_VERSION/ubuntu14

ADD ./download.sh /download.sh
RUN chmod +x /download.sh
#install iRODS
# install package dependencies to prevent Docker build from erring out
RUN apt-get update -qq ; apt-get upgrade -y -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq wget libcurl4-gnutls-dev psmisc rsync && \
    bash +x download.sh && \
    apt-get remove --auto-remove  -y --force-yes wget libcurl4-gnutls-dev && \
    apt-get autoremove -qq -y && apt-get clean -qq && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/apt/sources.list.d/*

ENV IRODS_DATA /export
RUN mkdir /opt/irods

ADD ./krb5.conf /etc/krb5.conf
ADD ./common-* /etc/pam.d/
ADD ./genresp.sh /opt/irods/genresp.sh
ADD ./setupdb.sh /opt/irods/setupdb.sh
ADD ./config.sh /opt/irods/config.sh
ADD ./pam.sh /opt/irods/pam.sh
ADD ./bootstrap.sh /opt/irods/bootstrap.sh
RUN chmod a+x /opt/irods/*.sh
ADD ./.export /.export
ADD ./cert.cfg /etc/irods/cert.cfg

EXPOSE 1247
#EXPOSE 1248
ENTRYPOINT "/opt/irods/bootstrap.sh"
