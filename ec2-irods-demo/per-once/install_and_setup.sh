#!/bin/bash

# build.sh
# Installs iRODS, Cloud Browser, s3 plugin, and WebDav

IRODS_FOLDER=$1
IRODS_VERSION=$2
DB_PLUGIN_FOLDER=$3
DB_PLUGIN_VERSION=$4


# prepare and install prerequisites
sudo apt-get update
sudo apt-get -y install postgresql openjdk-7-jdk
sudo update-java-alternatives -s java-1.7.0-openjdk-amd64
sudo apt-get -y install tomcat7 apache2
sudo apt-get -y install unzip

# install postgres and irods
wget -O /tmp/irods-icat.deb ftp://ftp.renci.org/pub/irods/releases/${IRODS_FOLDER}/ubuntu14/irods-icat-${IRODS_VERSION}-ubuntu14-x86_64.deb
wget -O /tmp/irods-postgres.deb ftp://ftp.renci.org/pub/irods/releases/${DB_PLUGIN_FOLDER}/ubuntu14/irods-database-plugin-postgres-${DB_PLUGIN_VERSION}-ubuntu14-x86_64.deb
sudo dpkg -i /tmp/irods-icat.deb /tmp/irods-postgres.deb
sudo apt-get -f -y install

# configure tomcat
sudo cp ./server.xml /etc/tomcat7

# configure cloud browser
wget -O /tmp/irods-cloud-backend.war https://code.renci.org/gf/download/frsrelease/239/2717/irods-cloud-backend.war
wget -O /tmp/irods-cloud-frontend.zip https://code.renci.org/gf/download/frsrelease/239/2712/irods-cloud-frontend.zip
sudo -u tomcat7 bash -c "cp /tmp/irods-cloud-backend.war /var/lib/tomcat7/webapps"
sudo unzip /tmp/irods-cloud-frontend.zip -d /var/www/
sudo sed -i 's/:8080//g' /var/www/irods-cloud-frontend/app/components/globals.js
sudo cp ./irods-cloud-backend-config.groovy /etc

# restart tomcat
sudo rm -rf /var/lib/tomcat7/webapps/ROOT
sudo service tomcat7 restart

# configure apache
sudo cp ./ajp.conf /etc/apache2/sites-available
sudo a2enmod proxy_ajp
sudo a2dissite 000-default
sudo a2dissite default-ssl
sudo a2ensite ajp
sudo service apache2 restart

# install s3 plugin
TMPFILE="/tmp/s3_plugin.deb"
S3_PLUGIN_DOWNLOAD="ftp://ftp.renci.org/pub/irods/plugins/irods_resource_plugin_s3/1.2/irods-resource-plugin-s3-1.2.deb"
sudo wget -O $TMPFILE $S3_PLUGIN_DOWNLOAD
sudo dpkg -i $TMPFILE

# configure MOTD and cron
sudo cp ./motd.tail /etc/
