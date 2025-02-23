#!/bin/bash

echo "Enter name for NKP Management Cluster : "
read NKPCLUSTER

if [[ "$NKPCLUSTER" == "" ]]; then
    echo "NKP CLUSTER name is empty. Exiting."
    exit 1
fi

DATACENTERS=$(govc find / -type Datacenter)
echo
echo "Select datacenter :"
select DATACENTER in $DATACENTERS; do 
    echo "you selected datacenter : ${DATACENTER}"
    echo 
    export GOVC_DATACENTER="${DATACENTER}"
    break
done
DATACENTER=$(echo "${GOVC_DATACENTER}" | rev | cut -d'/' -f1 | rev)

#list VM templates to build nkp image from
echo
echo "Select VM template to build NKP cluster with:"
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
VMSLIST=$(govc vm.info -json $DATACENTER/vm/* |jq -r '.virtualMachines[]|select (.config.template == true ) |.name')

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


echo "Select Cluster to deploy NKP"
CLUSTERS=$(govc find / -type ClusterComputeResource | rev | cut -d'/' -f1 | rev)
select CLUSTER in $CLUSTERS; do
    echo "you selected cluster : ${CLUSTER}"
    echo
    break
done

echo "Select Network to deploy NKP"

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

NETWORKS=$(govc find / -type Network)
echo
echo "Select network to set as default"
select NETWORK in $NETWORKS; do 
    echo "you selected network : ${NETWORK}"
    echo 
    export GOVC_NETWORK="${NETWORK}"
    break
done
IFS=$SAVEIFS

NETWORK=$(echo "${GOVC_NETWORK}" | rev | cut -d'/' -f1 | rev)

echo "Enter control plane VIP for NKP Management Cluster : "
read NKPCLUSTERVIP

if [[ "$NKPCLUSTERVIP" == "" ]]; then
    echo "NKP CLUSTER VIP is empty. Exiting."
    exit 1
fi

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
DATASTORES=$(govc find / -type Datastore |grep -i -v "local")
echo
echo "Select datastore :"
select DATASTORE in $DATASTORES; do 
    echo "you selected datastore : ${DATASTORE}"
    echo 
    export GOVC_DATASTORE="${DATASTORE}"
    break
done
DATASTORE=$(echo "${GOVC_DATASTORE}" | rev | cut -d'/' -f1 | rev)

FOLDERS=$(govc find / -type Folder)
echo
echo "Select Folder :"
select FOLDER in $FOLDERS; do 
    echo "you selected Resource Pool : ${FOLDER}"
    echo 
    export GOVC_FOLDER="${FOLDER}"
    break
done
FOLDER=$(echo "${GOVC_FOLDER}" | rev | cut -d'/' -f1 | rev)

RESOURCEPOOLS=$(govc find / -type ResourcePool)
echo
echo "Select Resource Pool to set as default"
select RESOURCEPOOL in $RESOURCEPOOLS; do 
    echo "you selected Resource Pool : ${RESOURCEPOOL}"
    echo 
    export GOVC_RESOURCE_POOL="${RESOURCEPOOL}"
    break
done
RESOURCE_POOL=$(echo "${GOVC_RESOURCE_POOL}" | rev | cut -d'/' -f1 | rev)
IFS=$SAVEIFS

echo "select public ssh key: "
sshkeys=$(ls ~/.ssh/*.pub)
select sshkey in $sshkeys; do 
    echo "you selected public ssh : ${sshkey}"
    LOCALKEY=$(echo ${sshkey} | rev | cut -d'/' -f1 | rev)
    cp $sshkey $LOCALKEY 
    echo 
    break
done

export VSPHERE_SERVER=$(govc env |grep -i url | cut -d "=" -f2)
export VSPHERE_USERNAME=$GOVC_USERNAME
export VSPHERE_PASSWORD=$GOVC_PASSWORD
export vsphere_password=$VSPHERE_PASSWORD

#get vcenter thumbprint
VCENTERTP=$(echo | openssl s_client -connect $VSPHERE_SERVER:443 2>/dev/null | openssl x509 -noout -fingerprint -sha256 | cut -d "=" -f2)

echo "command to run to deploy NKP:"
echo "nkp create cluster vsphere \
  --cluster-name ${NKPCLUSTER} \
  --network ${NETWORK} \
  --control-plane-endpoint-host ${NKPCLUSTERVIP} \
  --data-center ${DATACENTER} \
  --data-store ${DATASTORE} \
  --folder ${FOLDER} \
  --server ${VSPHERE_SERVER} \
  --ssh-public-key-file ${LOCALKEY} \
  --resource-pool ${RESOURCE_POOL} \
  --vm-template ${template} \
  --virtual-ip-interface "eth0" \
  --tls-thumb-print "${VCENTERTP}" \
  --registry-mirror-url https://registry.nutanixdemo.com/docker.io \
  --self-managed"

echo "press enter to continue or ctrl+c to exit"
read

nkp create cluster vsphere \
  --cluster-name ${NKPCLUSTER} \
  --network ${NETWORK} \
  --control-plane-endpoint-host ${NKPCLUSTERVIP} \
  --data-center ${DATACENTER} \
  --data-store ${DATASTORE} \
  --folder ${FOLDER} \
  --server ${VSPHERE_SERVER} \
  --ssh-public-key-file ${LOCALKEY} \
  --resource-pool ${RESOURCE_POOL} \
  --vm-template ${template} \
  --virtual-ip-interface "eth0" \
  --tls-thumb-print "${VCENTERTP}" \
  --registry-mirror-url https://registry.nutanixdemo.com/docker.io \
  --self-managed