#!/usr/bin/env bash

#------------------------------------------------------------------------------

# Copyright 2024 Nutanix, Inc
#
# Licensed under the MIT License;
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”),
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#------------------------------------------------------------------------------

# Maintainer:   Jose Gomez (jose.gomez@nutanix.com)
# Contributors: 

#------------------------------------------------------------------------------

# To run:
# curl -sL https://raw.githubusercontent.com/nutanixdev/nkp-quickstart/main/scripts/get-nkp-cli | bash

#------------------------------------------------------------------------------

source ./nkp-env

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

echo $bundlepath

#get registry ca-cert
ROOT_REGISTRY_URL=$(echo $AIRGAP_REGISTRY_MIRROR_URL | cut -d "/" -f1)
openssl s_client -connect $ROOT_REGISTRY_URL -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM > registry-ca_cert.pem
if [ $? -ne 0 ]; then
    echo "issue getting registry ca-cert."
    exit 1
fi

if [[ "$AIRGAP_REGISTRY_MIRROR_USERNAME" == "" ]]; then
    echo "AIRGAP_REGISTRY_MIRROR_USERNAME = empty. Exiting."
    exit 1
fi

if [[ "$AIRGAP_REGISTRY_MIRROR_PASSWORD" == "" ]]; then
    echo "AIRGAP_REGISTRY_MIRROR_PASSWORD = empty. Exiting."
    exit 1
fi

APPBUNDLE=$(ls $bundlepath/container-images/konvoy-image-bundle*)

nkp push bundle --bundle $APPBUNDLE \
  --to-registry=${AIRGAP_REGISTRY_MIRROR_URL} --to-registry-username="${AIRGAP_REGISTRY_MIRROR_USERNAME}"  \
  --to-registry-password="${AIRGAP_REGISTRY_MIRROR_PASSWORD}" --to-registry-ca-cert-file=registry-ca_cert.pem

if [ $? -ne 0 ]; then
    echo "issue pushing $APPBUNDLE."
    exit 1
fi

APPBUNDLE=$(ls $bundlepath/container-images/kommander-image-bundle*)

nkp push bundle --bundle $APPBUNDLE \
  --to-registry=${AIRGAP_REGISTRY_MIRROR_URL} --to-registry-username="${AIRGAP_REGISTRY_MIRROR_USERNAME}"  \
  --to-registry-password="${AIRGAP_REGISTRY_MIRROR_PASSWORD}" --to-registry-ca-cert-file=registry-ca_cert.pem


if [ $? -ne 0 ]; then
    echo "issue pushing $APPBUNDLE."
    exit 1
fi

APPBUNDLE=$(ls $bundlepath/container-images/nkp-catalog-applications*)

nkp push bundle --bundle $APPBUNDLE \
  --to-registry=${AIRGAP_REGISTRY_MIRROR_URL} --to-registry-username="${AIRGAP_REGISTRY_MIRROR_USERNAME}"  \
  --to-registry-password="${AIRGAP_REGISTRY_MIRROR_PASSWORD}" --to-registry-ca-cert-file=registry-ca_cert.pem

if [ $? -ne 0 ]; then
    echo "issue pushing $APPBUNDLE."
    exit 1
fi

docker load -i $bundlepath/nkp-image-builder-image-*

if [ $? -ne 0 ]; then
    echo "issue loding $bundlepath/nkp-image-builder-image-*."
    exit 1
fi

docker load -i $bundlepath/konvoy-bootstrap-image-*

if [ $? -ne 0 ]; then
    echo "issue loading $bundlepath/nkp-image-builder-image-*."
    exit 1
fi

docker images
