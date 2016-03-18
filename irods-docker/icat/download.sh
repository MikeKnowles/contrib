#!/usr/bin/env bash

if [ -n $ICAT_VERSION ]; then
    echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" >> /etc/apt/sources.list.d/pgdg.list
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client-9.4 krb5-admin-server libpam-krb5
    wget $FTP_URL/irods-database-plugin-postgres-$ICAT_PLUGIN-ubuntu14-x86_64.deb -O /tmp/irods-dbplugin.deb
    wget $FTP_URL/irods-icat-$IRODS_VERSION-ubuntu14-x86_64.deb -O /tmp/irods-icat.deb
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq `dpkg -I /tmp/irods-icat.deb | sed -n 's/^ Depends: //p' | sed 's/,//g'`
    dpkg -i /tmp/irods-icat.deb
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq `dpkg -I /tmp/irods-dbplugin.deb | sed -n 's/^ Depends: //p' | sed 's/,//g'`
    dpkg -i /tmp/irods-dbplugin.deb
else
    wget $FTP_URL/irods-resource-$IRODS_VERSION-ubuntu14-x86_64.deb -O /tmp/irods-resource.deb
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq `dpkg -I /tmp/irods-resource.deb | sed -n 's/^ Depends: //p' | sed 's/,//g'`
    dpkg -i /tmp/irods-resource.deb
fi