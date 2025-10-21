#!/bin/bash

#check if cluster-env file exists
if [ ! -f ./cluster-env ]; then
    echo "cluster-env file not found. Please create it with the required variables by cloning cluster-env.example."
    exit 1
fi
source ./cluster-env

nkp create cluster nutanix -c $CLUSTER_NAME \
    ${CLUSTER_HOSTNAME:+--cluster-hostname "$CLUSTER_HOSTNAME"} \
    --endpoint https://$NUTANIX_ENDPOINT:$NUTANIX_PORT \
    --insecure \
    --kubernetes-service-load-balancer-ip-range $LB_IP_RANGE \
    --control-plane-endpoint-ip $CONTROL_PLANE_ENDPOINT_IP \
    --control-plane-vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --control-plane-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --control-plane-subnets $NUTANIX_SUBNET_NAME \
    --control-plane-replicas $CONTROL_PLANE_REPLICAS \
    --worker-vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --worker-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --worker-subnets $NUTANIX_SUBNET_NAME \
    --worker-replicas $WORKER_NODES_REPLICAS \
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
    --dry-run -o yaml > $CLUSTER_NAME.yaml

if [ $? -ne 0 ]; then
    echo "Cluster creation failed. Please check the parameters in cluster-env."
    exit 1
else
    echo "Cluster definition created:  $CLUSTER_NAME.yaml"
    echo
    echo "to execute, run : kubectl apply -f $CLUSTER_NAME.yaml --server-side=true"
fi