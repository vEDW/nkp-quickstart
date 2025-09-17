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

#check if cli has kind option
KINDCHECK=$($bundlepath/cli/nkp create cluster nutanix -h | grep "\--kind-cluster-image")
if [ -z "$KINDCHECK" ]; then
    echo "kind option is not available in nkp cli. checking bootstrap instead"
     #check if cli has bootstrap option
    BOOTSTRAPCHECK=$($bundlepath/cli/nkp create cluster nutanix -h | grep "\--bootstrap-cluster-image")
    if [ -z "$BOOTSTRAPCHECK" ]; then
        unset BOOTSTRAPCHECK
        echo "bootstrap option is not available in nkp cli. can't delpoy without bootstrap or kind image"
        exit 1
    else
        echo "bootstrap option is available in nkp cli. enabling it"
        BOOTSTRAPCHECK="true"
        BOOTSTRAPIMAGE=$(ls $bundlepath/konvoy-bootstrap-image-*.tar)
        if [ -z "$BOOTSTRAPIMAGE" ]; then
            echo "No bootstrap image found in $bundlepath. can't delpoy without bootstrap or kind image"
            exit 1
        else
            echo "bootstrap image found: $BOOTSTRAPIMAGE"
        fi
    fi

else
    echo "kind option is available in nkp cli. enabling it"
    KINDCHECK="true"
fi
#check if cli has bundle option
KONVOYIMAGES=""
BUNDLECHECK=$($bundlepath/cli/nkp create image nutanix -h | grep "\--bundle")
if [ -n "$BUNDLECHECK" ]; then
   
    echo "checking container images in bundle"
    KONVOYIMAGES=$(ls $bundlepath/container-images/konvoy-image-bundle*)
    KOMMANDERIMAGES=$(ls $bundlepath/container-images/kommander-image-bundle*)
    if [ -z "$KONVOYIMAGES" ]; then
        echo "No konvoy image bundle found in $bundlepath/container-images. skipping."
        KONVOYIMAGES=""
    else
        echo "konvoy image bundle found: $KONVOYIMAGES"
    fi
    if [ -z "$KOMMANDERIMAGES" ]; then
        echo "No kommander image bundle found in $bundlepath/container-images. skipping."
        KOMMANDERIMAGES=""
    else
        echo "kommander image bundle found: $KOMMANDERIMAGES"
    fi
else
    echo "bundle option is not available in nkp cli. skipping bundle check."
    BUNDLECHECK=""
fi

$bundlepath/cli/nkp create cluster nutanix -c $CLUSTER_NAME \
    ${KINDCHECK:+--kind-cluster-image mesosphere/konvoy-bootstrap:$NKP_VERSION} \
    ${BOOTSTRAPCHECK:+--bootstrap-cluster-image $$BOOTSTRAPIMAGE} \
    --endpoint https://$NUTANIX_ENDPOINT:$NUTANIX_PORT \
    --insecure \
    --kubernetes-service-load-balancer-ip-range $LB_IP_RANGE \
    --control-plane-endpoint-ip $CONTROL_PLANE_ENDPOINT_IP \
    --control-plane-vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --control-plane-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --control-plane-subnets $NUTANIX_SUBNET_NAME \
    ${CONTROL_PLANE_REPLICAS:+--control-plane-replicas "$CONTROL_PLANE_REPLICAS"} \
    --worker-vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --worker-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --worker-subnets $NUTANIX_SUBNET_NAME \
    ${WORKER_NODES_REPLICAS:+--worker-replicas "$WORKER_NODES_REPLICAS"} \
    --csi-storage-container $NUTANIX_STORAGE_CONTAINER_NAME \
    --csi-hypervisor-attached-volumes=$CSI_HYPERVISOR_ATTACHED \
    ${SSH_PUBLIC_KEY_FILE:+--ssh-public-key-file "$SSH_PUBLIC_KEY_FILE"} \
    ${REGISTRY_MIRROR_URL:+--registry-mirror-url https://"$REGISTRY_MIRROR_URL"} \
    ${REGISTRY_MIRROR_USERNAME:+--registry-mirror-username "$REGISTRY_MIRROR_USERNAME"} \
    ${REGISTRY_MIRROR_PASSWORD:+--registry-mirror-password "$REGISTRY_MIRROR_PASSWORD"} \
    ${REGISTRY_URL:+--registry-url https://"$REGISTRY_URL"} \
    ${REGISTRY_USERNAME:+--registry-username "$REGISTRY_USERNAME"} \
    ${REGISTRY_PASSWORD:+--registry-password "$REGISTRY_PASSWORD"} \
    ${CP_CATEGORIES:+--control-plane-pc-categories "$CP_CATEGORIES"} \
    ${WORKER_CATEGORIES:+--worker-pc-categories "$WORKER_CATEGORIES"} \
    ${BUNDLECHECK:+--bundle "$KONVOYIMAGES,$KOMMANDERIMAGES"} \
    --self-managed --airgapped
