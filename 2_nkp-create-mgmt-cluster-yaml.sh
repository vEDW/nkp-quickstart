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

# Create the NKP cluster manifest
$bundlepath/cli/nkp create cluster preprovisioned \
  --cluster-name ${CLUSTER_NAME} \
  --control-plane-endpoint-host ${CLUSTER_VIP} \
  --virtual-ip-interface ${CLUSTER_VIP_ETH_INTERFACE} \
  --pre-provisioned-inventory-file=preprovisioned_inventory.yaml \
  --ssh-private-key-file=${SSH_PRIVATE_KEY_FILE} \
  --registry-mirror-url=${REGISTRY_MIRROR_URL} \
  --registry-mirror-username=${REGISTRY_MIRROR_USERNAME} \
  --registry-mirror-password=${REGISTRY_MIRROR_PASSWORD} \
  --registry-mirror-cacert=${REGISTRY_MIRROR_CA} \
  --worker-replicas=4 \
  --dry-run --output=yaml > ${CLUSTER_NAME}.yaml

  echo "Cluster manifest for ${CLUSTER_NAME} created at ${CLUSTER_NAME}.yaml"
  echo "You can apply this manifest to your management cluster with: kubectl apply -f ${CLUSTER_NAME}.yaml --server-side=true"