#!/bin/bash

#list VM templates to build nkp image from
echo "Select VM template to build NKP image from"
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
VMSLIST=$(govc ls vm)
select template in $VMSLIST; do
    template=$(echo $template | sed "s#$GOVC_DATACENTER/vm/##")
    echo "you selected template : ${template}"
    echo
    break
done
IFS=$SAVEIFS

#verify template is actually a VM
VMTEST=$(govc vm.info $GOVC_DATACENTER/vm/$template)
if [ $? -ne 0 ]; then
    echo "Template is not a VM. Exiting."
    exit 1
fi
echo "creating nkp image from $template"

CLUSTERS=$(govc find / -type ClusterComputeResource | rev | cut -d'/' -f1 | rev)
select CLUSTER in $CLUSTERS; do
    echo "you selected cluster : ${CLUSTER}"
    echo
    break
done

if [ "${GOVC_DATACENTER}" == "" ]; then
    echo "No datacenter specified, please set GOVC_DATACENTER environment variable"
    exit 1
fi
DATACENTER=$(echo "${GOVC_DATACENTER}" | rev | cut -d'/' -f1 | rev)

if [ "${GOVC_NETWORK}" == "" ]; then
    echo "No network specified, please set GOVC_NETWORK environment variable"
    exit 1
fi
NETWORK=$(echo "${GOVC_NETWORK}" | rev | cut -d'/' -f1 | rev)

if [ "${GOVC_DATASTORE}" == "" ]; then
    echo "No network specified, please set GOVC_NETWORK environment variable"
    exit 1
fi
DATASTORE=$(echo "${GOVC_DATASTORE}" | rev | cut -d'/' -f1 | rev)

if [ "${GOVC_RESOURCE_POOL}" == "" ]; then
    echo "No network specified, please set GOVC_NETWORK environment variable"
    exit 1
fi
RESOURCE_POOL=$(echo "${GOVC_RESOURCE_POOL}" | rev | cut -d'/' -f1 | rev)

echo "select public ssh key: "
LOCALKEYS=$(ls *_localkey)
select LOCALKEY in $LOCALKEYS; do
    echo "you selected key : ${LOCALKEY}"
    echo
    break
done

UBUNTUYAML=$(cat ./3_ubuntu_image.yaml)
UBUNTUYAML=$(echo "$UBUNTUYAML" |CLUSTER="$CLUSTER" yq e '.packer.cluster =env(CLUSTER)')
UBUNTUYAML=$(echo "$UBUNTUYAML" |DATACENTER="$DATACENTER" yq e '.packer.datacenter =env(DATACENTER)')
UBUNTUYAML=$(echo "$UBUNTUYAML" |NETWORK="$NETWORK" yq e '.packer.network =env(NETWORK)')
UBUNTUYAML=$(echo "$UBUNTUYAML" |DATASTORE="$DATASTORE" yq e '.packer.datastore =env(DATASTORE)')
UBUNTUYAML=$(echo "$UBUNTUYAML" |template="$template" yq e '.packer.template =env(template)')
UBUNTUYAML=$(echo "$UBUNTUYAML" |locakey="$LOCALKEY" yq e '.packer.ssh_private_key_file =env(locakey)')
UBUNTUYAML=$(echo "$UBUNTUYAML" | yq e '.packer.resource_pool ="/"')
UBUNTUYAML=$(echo "$UBUNTUYAML" | yq e '.packer.folder ="/"')

#need to add folder and RP
echo "$UBUNTUYAML" > $template.yaml
echo "nkp image $template.yaml created"
export VSPHERE_SERVER=$(govc env |grep -i url | cut -d "=" -f2)
export VSPHERE_USERNAME=$GOVC_USERNAME
export VSPHERE_PASSWORD=$GOVC_PASSWORD

yq e $template.yaml

echo "press enter to continue"
read
./konvoy-image build $template.yaml

