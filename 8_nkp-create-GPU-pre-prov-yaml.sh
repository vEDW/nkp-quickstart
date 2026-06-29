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
cat <<EOF > preprovisioned_inventory.yaml
---
apiVersion: infrastructure.cluster.konvoy.d2iq.io/v1alpha1
kind: PreprovisionedInventory
metadata:
  name: ${CLUSTER_NAME}-nodepool-gpu
  namespace: default
  labels:
    cluster.x-k8s.io/cluster-name: ${CLUSTER_NAME}
    clusterctl.cluster.x-k8s.io/move: ""
spec:
  hosts:
  - address: ${GPU_WORKER_1_ADDRESS}
  - address: ${GPU_WORKER_2_ADDRESS}
  - address: ${GPU_WORKER_3_ADDRESS}
  - address: ${GPU_WORKER_4_ADDRESS}  
  sshConfig:
    port: 22
    user: ${SSH_USER}
    privateKeyRef:
      name: ${SSH_PRIVATE_KEY_SECRET_NAME}
      namespace: default
EOF

nkp create nodepool preprovisioned -c ${MY_CLUSTER_NAME} ${MY_NODEPOOL_NAME} --override-secret-name ${MY_OVERRIDE_SECRET}
