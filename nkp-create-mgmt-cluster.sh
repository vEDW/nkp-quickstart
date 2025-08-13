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

$bundlepath/cli/nkp create cluster nutanix -c $CLUSTER_NAME \
    --kind-cluster-image mesosphere/konvoy-bootstrap:$NKP_VERSION \
    --endpoint https://$NUTANIX_ENDPOINT:$NUTANIX_PORT \
    --insecure \
    --kubernetes-service-load-balancer-ip-range $LB_IP_RANGE \
    --control-plane-endpoint-ip $CONTROL_PLANE_ENDPOINT_IP \
    --control-plane-vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --control-plane-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --control-plane-subnets $NUTANIX_SUBNET_NAME \
    --control-plane-replicas 3 \
    --worker-vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --worker-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --worker-subnets $NUTANIX_SUBNET_NAME \
    --worker-replicas 4 \
    --csi-storage-container $NUTANIX_STORAGE_CONTAINER_NAME \
    --csi-hypervisor-attached-volumes=true \
    --registry-mirror-url https://$REGISTRY_MIRROR_URL \
    --registry-mirror-username=$REGISTRY_MIRROR_USERNAME \
    --registry-mirror-password="$REGISTRY_MIRROR_PASSWORD" \
    --self-managed --airgapped
