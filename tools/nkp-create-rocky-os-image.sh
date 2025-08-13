#!/bin/bash

bundlepath=$(cat ../bundle-path)
if [ $? -ne 0 ]; then
    echo "no bundle-path file present."
    exit 1
fi

# Check if directory is empty
if [ -z "$bundlepath" ]; then
    echo "No content in dir $bundlepath. Exiting."
    exit 1
fi

echo "using airgap bundle: $bundlepath"

source ../nkp-env

OSVERSION=$($bundlepath/cli/nkp create image nutanix -h |grep "Create Nutanix Machine Image for one of" | grep -oP 'rocky-[0-9.]+')
$bundlepath/cli/nkp create image nutanix $OSVERSION \
    --endpoint https://$NUTANIX_ENDPOINT:$NUTANIX_PORT \
    --insecure \
    --cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --subnet $NUTANIX_SUBNET_NAME
if [ $? -ne 0 ]; then
    echo "issue creating rocky os image."
    exit 1
else
    echo "rocky os image created successfully."
fi