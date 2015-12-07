#!/bin/bash -e

function terminate_instance() {
    $AWSBIN ec2 terminate-instances --instance-ids $1
    if [ $? -eq 0 ] ; then
        echo "Instance [$1] has been terminated."
    fi
}

if [ $# -lt 2 ] ; then
   echo "usage:  $0 <irods_version> <db_plugin_version> [contrib_branch_name]"
   echo "example: $0 4.1.7 1.7 [master]"
   exit 1
fi

set +e; AWSBIN=$(which aws); set -e
if [ "$AWSBIN" == "" ] ; then
    echo "No AWS command line tools found... Try:"
    echo "  sudo pip install awscli"
    exit 1
fi

set +e; JQBIN=$(which jq); set -e
if [ "$JQBIN" == "" ] ; then
    echo "jq not found... Try:"
    echo "  sudo apt-get install jq"
    exit 1
fi

# update user_data_script.sh
IRODS_VERSION=$1
DB_PLUGIN_VERSION=$2
sed "s/TEMPLATE_IRODS_VERSION/$IRODS_VERSION/g" user_data_script.sh.template > user_data_script.sh
sed -i "s/TEMPLATE_DB_PLUGIN_VERSION/$DB_PLUGIN_VERSION/g" user_data_script.sh
BRANCH_NAME=$3
if [ $BRANCH_NAME == "" ] ; then $BRANCH_NAME = "master" ; fi
sed -i "s/TEMPLATE_BRANCH_NAME/$BRANCH_NAME/g" user_data_script.sh

# run instance from Ubuntu_14 base image
INSTANCE_ID=$($AWSBIN ec2 run-instances --image-id ami-bb14dad0 --security-groups "iRODS" --instance-type t2.micro --user-data file://user_data_script.sh | $JQBIN '.Instances[0].InstanceId' | sed 's/\"//g' )

if [ $? -eq 0 -a "$INSTANCE_ID" != "" ] ; then
    echo "Created instance [$INSTANCE_ID]"
else
    echo "Error encountered when creating instance [$INSTANCE_ID]"
    exit 1
fi

echo "Waiting for instance to be in a running state."
sleep 20

# wait for the instance to be in a running state
CURRENT_STATUS=initialization
CNTR=0
while [ $CURRENT_STATUS != "passed" -a $CNTR -lt 60 ] ; do
    CURRENT_STATUS=$($AWSBIN ec2 describe-instance-status --instance-ids $INSTANCE_ID | $JQBIN '.InstanceStatuses[0].InstanceStatus.Details[0].Status' | sed 's/\"//g')
    let CNTR=CNTR+1
    echo $CURRENT_STATUS
    sleep 10
done
echo "Instance [$INSTANCE_ID] is now running."

if [ $CNTR -eq 60 ] ; then
   echo "Timeout while waiting for [$INSTANCE_ID] to enter running state."
   terminate_instance $INSTANCE_ID
   exit 1
fi

# create image from this instance
IMAGE_VERSION=0
NEW_IMAGE_NAME="irods_${IRODS_VERSION}-${IMAGE_VERSION}_demo"
echo "Creating image [$NEW_IMAGE_NAME]"
$AWSBIN ec2 create-image --instance-id $INSTANCE_ID --name $NEW_IMAGE_NAME --description "iRODS $IRODS_VERSION with Cloud Browser on Ubuntu 14.04"
if [ $? -eq 0 ] ; then
    echo "Created image [$NEW_IMAGE_NAME]"
else
    echo "Error creating image."
    terminate_instance $INSTANCE_ID
    exit 1
fi

# terminate instance
sleep 60
terminate_instance $INSTANCE_ID
exit 0
