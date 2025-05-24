#!/bin/bash

OVAS=$(ls *.ova)
echo
echo "Select OVA to import"
select OVA in $OVAS; do 
    echo "you selected datacenter : ${OVA}"
    echo 
    break
done

govc import.spec $OVA > $OVA.json

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


if [ "${GOVC_RESOURCE_POOL}" == "" ]; then
    echo "No resource pool specified, please set GOVC_RESOURCE_POOL environment variable"
    exit 1
fi

echo "Enter name for new vm : "
read VMNAME

# get password for vm
echo "Enter password for new vm : "
read PASSWORD

echo "select public ssh key: "
sshkeys=$(ls ~/.ssh/*.pub)
if [ -z "$sshkeys" ]; then
    echo "No public ssh keys found in ~/.ssh/. creating a ssh key."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/nkp_ssh_key -N ""
    #check if error
    if [ $? -ne 0 ]; then
        echo "Failed to create ssh key. Exiting."
        exit 1
    fi
    echo "SSH key created."
    sshkeys=$(ls ~/.ssh/*.pub)
fi
select sshkey in $sshkeys; do 
    echo "you selected public ssh : ${sshkey}"
    privatekey=$(echo $sshkey | sed 's/.pub//')
    echo "private key : $privatekey"
    localkey=$(echo $privatekey | rev | cut -d'/' -f1 | rev)
    cp $privatekey "$VMNAME"_localkey
    echo 
    break
done

SSHKEYCONTENT=$(cat $sshkey)
UBUNTU_TEMPLATE=$(cat $OVA.json | jq '.')
UBUNTU_TEMPLATE=$(echo "$UBUNTU_TEMPLATE" | jq '.DiskProvisioning = "thin"')
UBUNTU_TEMPLATE=$(echo "$UBUNTU_TEMPLATE" | jq --arg VMNAME "$VMNAME" '.Name = $VMNAME')
UBUNTU_TEMPLATE=$(echo "$UBUNTU_TEMPLATE" | jq --arg VMNAME "$VMNAME" '.PropertyMapping |= map(if .Key == "hostname" then .Value = $VMNAME else . end)')
UBUNTU_TEMPLATE=$(echo "$UBUNTU_TEMPLATE" | jq --arg NETWORK "$NETWORK" '.NetworkMapping |= map(if .Name == "VM Network" then .Network = $NETWORK else . end)')
UBUNTU_TEMPLATE=$(echo "$UBUNTU_TEMPLATE" | jq --arg password "$PASSWORD" '.PropertyMapping |= map(if .Key == "password" then .Value = $password else . end)')
UBUNTU_TEMPLATE=$(echo "$UBUNTU_TEMPLATE" | jq --arg SSH "$SSHKEYCONTENT" '.PropertyMapping |= map(if .Key == "public-keys" then .Value = $SSH else . end)')

echo "${UBUNTU_TEMPLATE}" > $OVA.json
echo 
echo "verify json file : $OVA.json"
echo
jq . $OVA.json
echo
read -p "Press enter to continue or CTRL-C to quit"
echo
govc import.ova -options=$OVA.json $OVA
#govc upgrade virtual hardware
govc vm.upgrade -vm $VMNAME
#pgrade disk capacity to80G
DISKKEY=$(govc vm.info -json $VMNAME |jq '.virtualMachines[].layoutEx.disk[].key')
govc vm.disk.change -vm $VMNAME -disk.key $DISKKEY -size 80G
echo "Disk size increased to 80G"

govc vm.power -on $VMNAME

echo "VM $VMNAME created and started"
#wait for ip address
echo "waiting for ip address"
while true; do
    IP=$(govc vm.info -json $VMNAME | jq -r '.virtualMachines[].guest.ipAddress')
    if [ "$IP" != "null" ]; then
        echo "IP address : $IP"
        break
    fi
    sleep 5
done
echo
echo "VM $VMNAME is ready"
echo
echo "ssh ubuntu@$IP"
echo
echo "checking disk space"
ssh -i $privatekey -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  ubuntu@$IP df -h
echo 
echo "shutting down VM"
ssh -i $privatekey -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  ubuntu@$IP "sudo shutdown -h now"
echo "waiting for VM to shutdown"
while true; do
    STATUS=$(govc vm.info -json $VMNAME | jq -r '.virtualMachines[].runtime.powerState')
    if [ "$STATUS" == "poweredOff" ]; then
        echo "VM $VMNAME is powered off"
        break
    fi
    sleep 5
done
echo "Creating kib snapshot"
govc snapshot.create -vm $VMNAME -d "konvoy image builder snapshot" kib
echo "snapshot created"
