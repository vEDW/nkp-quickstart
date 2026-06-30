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


curl -O https://download.nvidia.com/XFree86/Linux-x86_64/580.126.18/NVIDIA-Linux-x86_64-580.126.18.run
if [ $? -ne 0 ]; then
    echo "Failed to download NVIDIA driver."
    exit 1
fi

mv NVIDIA-Linux-x86_64-580.126.18.run ${ARTIFACTS_DIRECTORY}/


export NVIDIA_RUNFILE="${ARTIFACTS_DIRECTORY}/NVIDIA-Linux-x86_64-580.126.18.run"

echo "NVIDIA_RUNFILE set to: ${NVIDIA_RUNFILE}"
