#!/bin/bash

echo "Downloading Nutanix CSI charts for offline installation"

source ./nkp-env

# get csi charts
#csi snapshot
CSISNAPSHOTVERSION=8.3.0
echo
echo "Downloading Nutanix CSI Snapshot chart version ${CSISNAPSHOTVERSION}"
echo
wget https://github.com/nutanix/helm-releases/releases/download/nutanix-csi-snapshot-${CSISNAPSHOTVERSION}/nutanix-csi-snapshot-${CSISNAPSHOTVERSION}.tgz
# check if error
if [ $? -ne 0 ]; then
    echo "Failed to download nutanix-csi-snapshot-${CSISNAPSHOTVERSION}.tgz"
    exit 1
fi

echo "Extracting Nutanix CSI Snapshot chart"
echo

tar zxvf nutanix-csi-snapshot-${CSISNAPSHOTVERSION}.tgz
# check if error
if [ $? -ne 0 ]; then
    echo "Failed to extract nutanix-csi-snapshot-${CSISNAPSHOTVERSION}.tgz"
    exit 1
fi

#csi driver
CSISTORAGEVERSION=3.3.8
echo "Downloading Nutanix CSI Storage chart version ${CSISTORAGEVERSION}"
echo
wget https://github.com/nutanix/helm-releases/releases/download/nutanix-csi-storage-${CSISTORAGEVERSION}/nutanix-csi-storage-${CSISTORAGEVERSION}.tgz
# check if error
if [ $? -ne 0 ]; then
    echo "Failed to download nutanix-csi-storage-${CSISTORAGEVERSION}.tgz"
    exit 1
fi
echo "Extracting Nutanix CSI Storage chart"
echo
tar zxvf nutanix-csi-storage-${CSISTORAGEVERSION}.tgz
# check if error
if [ $? -ne 0 ]; then
    echo "Failed to extract nutanix-csi-storage-${CSISTORAGEVERSION}.tgz"
    exit 1
fi
