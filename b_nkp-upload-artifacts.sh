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

OS_TYPE="rhel-9.6"

ARTIFACTS_DIRECTORY="$bundlepath/image-artifacts"


# Create the NKP cluster manifest
$bundlepath/cli/nkp upload image-artifacts \
  --ssh-host "${CONTROL_PLANE_1_ADDRESS},${CONTROL_PLANE_2_ADDRESS},${CONTROL_PLANE_3_ADDRESS},${WORKER_1_ADDRESS},${WORKER_2_ADDRESS},${WORKER_3_ADDRESS},${WORKER_4_ADDRESS}" \
  --ssh-username "${SSH_USER}" \
  ${SSH_PRIVATE_KEY_FILE:+--ssh-private-key-file="$SSH_PRIVATE_KEY_FILE"} \
  ${SSH_PASSWORD:+--ssh-password="$SSH_PASSWORD"} \
  ${SSH_PORT:+--ssh-port="$SSH_PORT"} \
  --artifacts-directory "${ARTIFACTS_DIRECTORY}" \
  ${PROVIDER:+--provider="$PROVIDER"} \
  ${FIPS_ENABLED:+--fips}