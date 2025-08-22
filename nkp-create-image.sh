#!/bin/bash

bundlepath=$(cat bundle-path)
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

source ./nkp-env

NKP_VERSION=$($bundlepath/cli/nkp version -o=json |jq -r '.nkp.gitVersion')
if [ $? -ne 0 ]; then
    echo "nkp cli not found in $bundlepath/cli/nkp"
    exit 1
fi

#get OS list
OSOPTIONS=$($bundlepath/cli/nkp create image nutanix -h |grep "Create Nutanix Machine Image for one of" | grep -oP '(rocky|ubuntu|rhel)-[0-9.]+' ) #| tr '\n' ' ')
if [ $? -ne 0 ]; then
    echo "issue getting OS options."
    exit 1
fi
#select OS
echo
echo "Select the OS to create image for :"
select OSCHOSEN in $OSOPTIONS; do 
    echo "you selected OS version : ${OSCHOSEN}"
    echo 
    break
done

#check if cli has bundle option
KONVOYIMAGES=""
BUNDLECHECK=$($bundlepath/cli/nkp create image nutanix -h | grep "\--bundle")
if [ -n "$BUNDLECHECK" ]; then
    echo "checking container images in bundle"
    KONVOYIMAGES=$(ls $bundlepath/container-images/konvoy-image-bundle*)
    if [ -z "$KONVOYIMAGES" ]; then
        echo "No konvoy image bundle found in $bundlepath/container-images. skipping."
        KONVOYIMAGES=""
    else
        echo "konvoy image bundle found: $KONVOYIMAGES"
    fi
else
    echo "bundle option is not available in nkp cli. skipping bundle check."
    BUNDLECHECK=""
fi

$bundlepath/cli/nkp create image nutanix $OSCHOSEN \
    --endpoint https://$NUTANIX_ENDPOINT:$NUTANIX_PORT \
    --insecure \
    --subnet $NUTANIX_SUBNET_NAME \
    --cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    ${KONVOYIMAGES:+--bundle "$KONVOYIMAGES"} \
