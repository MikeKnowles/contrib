#!/bin/bash
RODS_PASSWORD=$1

set -e
# Wait for progres
while [ ! -s /export/pgdata ];
do
    echo -n "Waiting for postgres"
    sleep 5
done;

if [ -d /export ]; then
    if [ ! -s /export/.export ]; then
        cp /.export /export/.export
    fi
    while read f; do

        if [ ! -d ${f} ]; then
            mkdir -p /export${f}
        else
            rsync --ignore-existing -prRALE ${f} /export
            rm -rf ${f}
        fi
        chown -R 999:999 /export${f}
        ln -s /export${f} ${f}
    done </export/.export
fi

# Grab postgres env: should pass properly in docker compose
if [ -z "$POSTGRES_SERVER" ]
  then
    export POSTGRES_SERVER="localhost"
fi

if [ -z "$POSTGRES_PASSWORD" ]
  then
    export POSTGRES_PASSWORD="mysecretpassword"
fi

if [ -z "$POSTGRES_USER" ]
  then
    export POSTGRES_USER="irods"
fi

if [ -z "$POSTGRES_DB" ]
  then
    export POSTGRES_DB="ICAT"
fi

if [ ! -z ${ICAT_PLUGIN+x} ]; then
    # Only generate the setup_responses file if it does not exist
    if [ ! -s /export/etc/irods/setup_responses ]; then
        # generate configuration responses
        /opt/irods/genresp.sh /etc/irods/setup_responses
        if [ -n "$RODS_PASSWORD" ]
          then
            sed -i "14s/.*/$RODS_PASSWORD/" /etc/irods/setup_responses
        fi
    fi

    # Not sure if this is neccesary
    #if [ -s /export/var/lib/irods/.irods/.irodsEnv ]; then
    #    sed -i 's/^irodsHost.*/irodsHost localhost/' /var/lib/irods/.irods/.irodsEnv
    #
    #fi
    # Copy & rm then link folders in export, need to add option for files

    # set up PAM auth
    source /opt/irods/pam.sh
    # set up the iCAT database
    /opt/irods/setupdb.sh /etc/irods/setup_responses
fi
# Create the previous variables for IRODS_SERVICE_ACCOUNT_NAME
if [ -e /etc/irods/service_account.config ]; then
    source /etc/irods/service_account.config
    head -n 2 /etc/irods/setup_responses | /var/lib/irods/packaging/setup_irods_service_account.sh
    sudo su - ${IRODS_SERVICE_ACCOUNT_NAME} -c "touch /var/lib/${IRODS_SERVICE_ACCOUNT_NAME}/packaging/binary_installation.flag"
    sudo su - ${IRODS_SERVICE_ACCOUNT_NAME} -c "mkdir -p /tmp/${IRODS_SERVICE_ACCOUNT_NAME}/"
    sudo su - ${IRODS_SERVICE_ACCOUNT_NAME} -c "touch /tmp/${IRODS_SERVICE_ACCOUNT_NAME}/setup_irods_database.flag"
    sudo su - ${IRODS_SERVICE_ACCOUNT_NAME} -c "touch /tmp/${IRODS_SERVICE_ACCOUNT_NAME}/setup_irods_resource.flag"
    sudo su - ${IRODS_SERVICE_ACCOUNT_NAME} -c "touch /tmp/${IRODS_SERVICE_ACCOUNT_NAME}/setup_irods_configuration.flag"
    # For some reason, the native auth scheme is set by default for the server
#    sed -e 's/native/PAM/' -i /var/lib/irods/iRODS/scripts/perl/irods_setup.pl
    if [ -z ${ICAT_PLUGIN+x} ]; then
        while [ `wc -l /export/etc/irods/setup_responses | awk '{print $1}'` -lt "21" ]; do
            sleep 5
        done
        arr=( $(sed -n -e 4,+9p -e 15p -e '16a\icat' /export/etc/irods/setup_responses && \
         sed -n -e 3p -e '4a\yes' -e 14p -e 21p /export/etc/irods/setup_responses) )
    else
        tail -n +3 /etc/irods/setup_responses | /var/lib/irods/packaging/setup_irods.sh
    fi
else
    if [ -z ${ICAT_PLUGIN+x} ]; then
        while [ `wc -l /export/etc/irods/setup_responses | awk '{print $1}'` -lt "21" ]; do
            sleep 5
        done
        arr=( $(sed -n -e 1,2p -e 4,+9p -e 15p -e '16a\icat' /export/etc/irods/setup_responses && \
         sed -n -e 3p -e '4a\yes' -e 14p -e 21p /export/etc/irods/setup_responses) )
    else
        /opt/irods/config.sh /etc/irods/setup_responses
    fi
    # set up iRODS

fi
if [ -z ${ICAT_PLUGIN+x} ]; then
    for line in ${arr[@]}; do
        echo "${line}"
    done | /var/lib/irods/packaging/setup_irods.sh
fi
sed 's@\("irods_host"\)@"irods_authentication_scheme": "PAM",\
    "irods_ssl_ca_certificate_file": "/etc/irods/chain.pem",\
    "irods_ssl_certificate_chain_file": "/etc/irods/chain.pem",\
    "irods_ssl_certificate_key_file": "/etc/irods/server.key",\
    "irods_ssl_dh_params_file": "/etc/irods/dhparams.pem",\
    "irods_ssl_certificate_ca_file": "/etc/irods/chain.pem",\
    "irods_ssl_verify_server": "cert",\
    \1@' -i /var/lib/irods/.irods/irods_environment.json


# this script must end with a persistent foreground process
tail -f /var/lib/irods/iRODS/server/log/rodsLog.*
#sleep infinity
