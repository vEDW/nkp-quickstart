#!/bin/bash


govc datastore.mkdir -ds=/RXManaged/PHX/326641/datastore/default-container-71412077035297/ ISO
govc datastore.upload -ds=/RXManaged/PHX/326641/datastore/default-container-71412077035297 /tmp/ubuntu-22.04.5-live-server-amd64.iso ISO/ubuntu-22.04.5-live-server-amd64.iso
VMNAME=ubuntu-2204
GOVC_NETWORK=vlan-0
GOVC_DATASTORE=/RXManaged/PHX/326641/datastore/default-container-71412077035297
CPU=2
MEMORY=4096
DISK_SIZE=80GB  
ISO_PATH="[default-container-71412077035297] ISO/ubuntu-22.04-live-server-amd64.iso"
DATASTORE="/RXManaged/PHX/326641/datastore/default-container-71412077035297"
govc vm.create -ds="$DATASTORE"  -net $GOVC_NETWORK -c=$CPU -m=$MEMORY -g=ubuntu64Guest -disk=$DISK_SIZE -iso="$ISO_PATH" -on=false $VMNAME 
govc device.cdrom.insert -vm $VMNAME -device cdrom-3000 $CD_ISO_PATH

govc vm.power -on "$VMNAME"


CD_ISO_PATH="$DATASTORE/ISO/ubuntu-22.04-live-server-amd64.iso"


govc vm.keystrokes -vm $VMNAME -c KEY_ENTER
govc vm.keystrokes -vm $VMNAME -c KEY_ENTER
govc vm.keystrokes -vm $VMNAME -c KEY_ENTER
govc vm.keystrokes -vm $VMNAME -c KEY_UP
govc vm.keystrokes -vm $VMNAME -c KEY_UP
govc vm.keystrokes -vm $VMNAME -c KEY_SPACE
govc vm.keystrokes -vm $VMNAME -c KEY_ENTER
govc vm.keystrokes -vm $VMNAME -c KEY_DOWN
govc vm.keystrokes -vm $VMNAME -c KEY_DOWN
govc vm.keystrokes -vm $VMNAME -c KEY_ENTER

#convert VM to template.

# start konvoy image builder
export SSH_USERNAME=nutanix
export SSH_PASSWORD='nutanix/4u'

export VSPHERE_SERVER="10.2.81.21"
export VSPHERE_USERNAME=$GOVC_USERNAME
export VSPHERE_PASSWORD=$GOVC_PASSWORD

./konvoy-image create-package-bundle --os ubuntu-2204 --output-directory=artifacts
./konvoy-image build vsphere --datacenter 326641 --cluster PHX-POC240 --datastore $DATASTORE --network $GOVC_NETWORK --template=ubuntu-2204 images/ova/ubuntu-2204.yaml --dry-run
