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

cat <<EOF > nvidia.yaml
gpu:
  types:
    - nvidia
build_name_extra: "-nvidia"
nvidia_driver_version: "580.95.05"
EOF

kubectl create secret generic ${CLUSTER_NAME}-gpu-overrides --from-file=overrides.yaml=nvidia.yaml


cat <<EOF > preprovisioned_GPU_inventory.yaml
---
apiVersion: infrastructure.cluster.konvoy.d2iq.io/v1alpha1
kind: PreprovisionedInventory
metadata:
  name: ${CLUSTER_NAME}-nodepool-gpu
  namespace: default
  labels:
    cluster.x-k8s.io/cluster-name: ${CLUSTER_NAME}
spec:
  hosts:
  - address: ${GPU_WORKER_1_ADDRESS}
  sshConfig:
    port: 22
    user: ${SSH_USER}
    privateKeyRef:
      name: ${SSH_PRIVATE_KEY_SECRET_NAME}
      namespace: default
EOF

kubectl apply -f preprovisioned_GPU_inventory.yaml

nkp create nodepool preprovisioned -c ${CLUSTER_NAME} ${CLUSTER_NAME}-nodepool-gpu \
  ${REGISTRY_MIRROR_URL:+--registry-mirror-url https://"$REGISTRY_MIRROR_URL"} \
  ${REGISTRY_MIRROR_USERNAME:+--registry-mirror-username "$REGISTRY_MIRROR_USERNAME"} \
  ${REGISTRY_MIRROR_PASSWORD:+--registry-mirror-password "$REGISTRY_MIRROR_PASSWORD"} \
  ${REGISTRY_MIRROR_CA:+--registry-mirror-cacert "$REGISTRY_MIRROR_CA"} \
  ${WORKER_NODES_REPLICAS:+--worker-replicas "$WORKER_NODES_REPLICAS"} \
  --override-secret-name ${CLUSTER_NAME}-gpu-overrides

