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
echo "Select NKP template to cleanup"
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
VMSLIST=$(govc find / -type m -config.template true)
select template in $VMSLIST; do
    template=$(echo $template | sed "s#$GOVC_DATACENTER/vm/##")
    echo "you selected template : ${template}"
    echo
    break
done
IFS=$SAVEIFS

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


#convert template to VM.

govc vm.markasvm $template
if [ $? -ne 0 ]; then
    echo "issue converting template to VM."
    exit 1
fi
#start VM
govc vm.power -on $template
if [ $? -ne 0 ]; then
    echo "issue powering on VM."
    exit 1
fi

#wait for ip address
echo "waiting for ip address"
while true; do
    IP=$(govc vm.info -json $template | jq -r '.virtualMachines[].guest.ipAddress')
    if [ "$IP" != "null" ]; then
        echo "IP address : $IP"
        break
    fi
    sleep 5
done
echo
echo "VM $template is ready"
echo

# Proceed with cleanup
echo "Proceeding with cleanup of VM $template"
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

COMMANDLIST="sudo systemctl stop openvswitch-switch
sudo rm -f /etc/openvswitch/conf.db /etc/openvswitch/system-id.conf
sudo cloud-init clean --logs
sudo truncate -s 0 /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
sudo rm -f /etc/ssh/ssh_host_*
sudo find /var/log -type f -exec truncate -s 0 {} \;
history -c && history -w && sudo shutdown -h now"

for cmd in "${COMMANDLIST[@]}"; do
    echo "Running command: $cmd"
    ssh -i $privatekey -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@$IP "$cmd"
    if [ $? -ne 0 ]; then
        echo "issue running command: $cmd"
        exit 1
    fi
done
IFS=$SAVEIFS

echo "waiting for VM to shutdown"
while true; do
    STATUS=$(govc vm.info -json $VMNAME | jq -r '.virtualMachines[].runtime.powerState')
    if [ "$STATUS" == "poweredOff" ]; then
        echo "VM $VMNAME is powered off"
        break
    fi
    sleep 5
done

echo "Converting back to template"
govc vm.markastemplate $template
if [ $? -ne 0 ]; then
    echo "issue converting VM back to template."
    exit 1
fi

END=$( date +%s )
TIME=$( expr ${END} - ${START} )
TIME=$(date -d@$TIME -u +%Hh%Mm%Ss)
echo
echo "=========================="
echo "===  NKP image created ==="
echo "=== In ${TIME} ==="
echo "=========================="
