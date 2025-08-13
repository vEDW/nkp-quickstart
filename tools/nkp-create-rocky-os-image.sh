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
echo 
source ../nkp-env

echo "extracting rocky os info from nkp cli"
OSVERSION=$($bundlepath/cli/nkp create image nutanix -h |grep "Create Nutanix Machine Image for one of" | grep -oP 'rocky-[0-9.]+')
if [ $? -ne 0 ]; then
    echo "issue getting rocky os version."
    exit 1
fi
echo "rocky os version: $OSVERSION"
echo 
echo "creating rocky os image..."
$bundlepath/cli/nkp create image nutanix $OSVERSION \
    --endpoint https://$NUTANIX_ENDPOINT \
    --insecure \
    --cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --subnet $NUTANIX_SUBNET_NAME
if [ $? -ne 0 ]; then
    echo "issue creating rocky os image."
    exit 1
else
    echo "rocky os image created successfully."
fi