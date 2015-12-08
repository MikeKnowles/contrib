#!/bin/bash
FQDN_LOCATION="/var/tmp/FQDN"
OLD_FQDN=""
if [ -e $FQDN_LOCATION ] ; then
    OLD_FQDN=`sudo cat $FQDN_LOCATION`
fi
NEW_FQDN=`ec2metadata --public-hostname`

# if the hostname has changed
if [ "$NEW_FQDN" != "$OLD_FQDN" ] ; then
    # write it down
    echo $NEW_FQDN > $FQDN_LOCATION

    # update hostname
    sudo hostname $NEW_FQDN
    sudo su -c "echo $NEW_FQDN > /etc/hostname"

    # update the irods service account's user environment
    sudo -u irods bash -c 'sed  -i "s|\(.*irods_host.*\)'$OLD_FQDN'\(.*\)|\1'$NEW_FQDN'\2|g" ~irods/.irods/irods_environment.json'

    # update the resource host information
    sudo su - irods -c "iadmin modresc demoResc host $NEW_FQDN"
fi
