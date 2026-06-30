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
ARTIFACTS_DIRECTORY="$bundlepath/image-artifacts"

FILENAME=$(basename "$NVIDIA_URL")

curl -O ${NVIDIA_URL}
if [ $? -ne 0 ]; then
    echo "Failed to download NVIDIA driver."
    exit 1
fi

mv ${FILENAME} ${ARTIFACTS_DIRECTORY}/


export NVIDIA_RUNFILE="${ARTIFACTS_DIRECTORY}/${FILENAME}"

echo "NVIDIA_RUNFILE set to: ${NVIDIA_RUNFILE}"
