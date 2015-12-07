#!/bin/bash

# deploy_software.sh
# Run once to setup iRODS on a new instance

IRODS_FOLDER=$1
IRODS_VERSION=$2
DB_PLUGIN_FOLDER=$3
DB_PLUGIN_VERSION=$4

cd ./per-once/
./install_and_setup.sh $IRODS_FOLDER $IRODS_VERSION $DB_PLUGIN_FOLDER $DB_PLUGIN_VERSION > install_and_setup.sh.out
