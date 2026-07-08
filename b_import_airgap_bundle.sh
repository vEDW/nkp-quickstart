#!/bin/bash

source ./nkp-env

#select tar file to import

TARFILES=$(ls *.tar)
if [ $? -ne 0 ]; then
    echo "no tar files found in current directory."
    exit 1
fi

echo "Select the tar file to import:"
select TARFILE in $TARFILES; do
    if [ -n "$TARFILE" ]; then
        echo "You selected: $TARFILE"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

nkp push bundle --bundle $TARFILE \
  --to-registry=${AIRGAP_REGISTRY_MIRROR_URL} --to-registry-username="${AIRGAP_REGISTRY_MIRROR_USERNAME}"  \
  --to-registry-password="${AIRGAP_REGISTRY_MIRROR_PASSWORD}" --to-registry-ca-cert-file="${AIRGAP_REGISTRY_MIRROR_CA_CERT_FILE}"