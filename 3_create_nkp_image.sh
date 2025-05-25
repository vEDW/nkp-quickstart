#!/bin/bash

#start timer
START=$( date +%s ) 

#check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "yq could not be found, please install it first."
    exit 1
fi

#check if govc is installed
if ! command -v govc &> /dev/null; then
    echo "govc could not be found, please install it first."
    exit 1
fi

#check if bundle-path is present
bundlepath=$(cat bundle-path)
if [ $? -ne 0 ]; then
    echo "no bundle-path file present. please run 0_get_airgap_bundle.sh first"
    exit 1
fi

# Check if directory is empty
if [ -z "$bundlepath" ]; then
    echo "No content in dir $bundlepath. Exiting."
    exit 1
fi
echo
echo "using airgap bundle : $bundlepath"
echo

if [ "${GOVC_DATACENTER}" == "" ]; then
    echo "No datacenter specified, please set GOVC_DATACENTER environment variable"
    exit 1
fi
#DATACENTER=$(echo "${GOVC_DATACENTER}" | rev | cut -d'/' -f1 | rev)
DATACENTER="${GOVC_DATACENTER}"

if [ "${GOVC_NETWORK}" == "" ]; then
    echo "No network specified, please set GOVC_NETWORK environment variable"
    exit 1
fi
#NETWORK=$(echo "${GOVC_NETWORK}" | rev | cut -d'/' -f1 | rev)
NETWORK="${GOVC_NETWORK}"

if [ "${GOVC_DATASTORE}" == "" ]; then
    echo "No network specified, please set GOVC_NETWORK environment variable"
    exit 1
fi
#DATASTORE=$(echo "${GOVC_DATASTORE}" | rev | cut -d'/' -f1 | rev)
DATASTORE="${GOVC_DATASTORE}"

if [ "${GOVC_RESOURCE_POOL}" == "" ]; then
    echo "No network specified, please set GOVC_NETWORK environment variable"
    exit 1
fi
#RESOURCE_POOL=$(echo "${GOVC_RESOURCE_POOL}" | rev | cut -d'/' -f1 | rev)
RESOURCE_POOL="${GOVC_RESOURCE_POOL}"

#list VM templates to build nkp image from
echo "Select base VM to build NKP image from"
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
VMSLIST=$(govc find / -type m |grep -v CVM)
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
echo
echo "creating nkp image from $template"
echo
echo "Select Cluster to deploy NKP image to"

#CLUSTERS=$(govc find / -type ClusterComputeResource | rev | cut -d'/' -f1 | rev)
CLUSTERS=$(govc find  ${GOVC_DATACENTER} -type ClusterComputeResource)
select CLUSTER in $CLUSTERS; do
    echo "you selected cluster : ${CLUSTER}"
    break
done

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
echo
echo "Select Folder to deploy NKP image to"
FOLDERS=$(govc find  ${GOVC_DATACENTER} -type Folder |grep vm | rev | cut -d'/' -f1 | rev)
select FOLDER in $FOLDERS; do
    echo "you selected cluster : ${FOLDER}"
    echo
    break
done
IFS=$SAVEIFS
echo
echo "select public ssh key: "
LOCALKEYS=$(ls *_localkey)
if [ -z "$LOCALKEYS" ]; then
    echo "No local keys found. Please create a key first."
    exit 1
fi
select LOCALKEY in $LOCALKEYS; do
    echo "you selected key : ${LOCALKEY}"
    echo
    break
done

UBUNTUYAML=$(cat ./ubuntu_image.yaml)
UBUNTUYAML=$(echo "$UBUNTUYAML" |CLUSTER="$CLUSTER" yq e '.packer.cluster =env(CLUSTER)')
UBUNTUYAML=$(echo "$UBUNTUYAML" |DATACENTER="$DATACENTER" yq e '.packer.datacenter =env(DATACENTER)')
UBUNTUYAML=$(echo "$UBUNTUYAML" |NETWORK="$NETWORK" yq e '.packer.network =env(NETWORK)')
UBUNTUYAML=$(echo "$UBUNTUYAML" |DATASTORE="$DATASTORE" yq e '.packer.datastore =env(DATASTORE)')
UBUNTUYAML=$(echo "$UBUNTUYAML" |RESOURCE_POOL="$RESOURCE_POOL" yq e '.packer.resource_pool =env(RESOURCE_POOL)')
UBUNTUYAML=$(echo "$UBUNTUYAML" |FOLDER="$FOLDER" yq e '.packer.folder =env(FOLDER)')
UBUNTUYAML=$(echo "$UBUNTUYAML" |template="$template" yq e '.packer.template =env(template)')
UBUNTUYAML=$(echo "$UBUNTUYAML" |locakey="$LOCALKEY" yq e '.packer.ssh_private_key_file =env(locakey)')

#need to add folder and RP
echo
echo "$UBUNTUYAML" > $template.yaml
echo "nkp image $template.yaml created"
export VSPHERE_SERVER=$(govc env |grep -i url | cut -d "=" -f2)
export VSPHERE_USERNAME=$GOVC_USERNAME
export VSPHERE_PASSWORD=$GOVC_PASSWORD

yq e $template.yaml

echo "press enter to continue"
read

CURRENTDIR=$(pwd)
#copy files to kib folder
cp $LOCALKEY $bundlepath/kib/
cp $template.yaml $bundlepath/kib/
#build nkp image
cd $bundlepath/kib
./konvoy-image build $template.yaml
if [ $? -ne 0 ]; then
    echo "Failed to build nkp image. Exiting."
    exit 1
fi
cd $CURRENTDIR

END=$( date +%s )
TIME=$( expr ${END} - ${START} )
TIME=$(date -d@$TIME -u +%Hh%Mm%Ss)
echo
echo "=========================="
echo "===  NKP image created ==="
echo "=== In ${TIME} ==="
echo "=========================="
