#!/bin/bash

GOVCRELEASE=$(curl -s https://api.github.com/repos/vmware/govmomi/releases/latest | jq -r .tag_name)

if [[ ${GOVCRELEASE} == "null" ]]; then
    echo "github api rate limiting blocked request"
    echo "please set GOVCRELEASE version in define_download_version_env"
    exit
fi

curl -s -LO https://github.com/vmware/govmomi/releases/download/${GOVCRELEASE}/govc_Linux_x86_64.tar.gz

mkdir -p ./govctar
tar -zxf govc_Linux_x86_64.tar.gz -C  ./govctar
sudo chown root:root ./govctar/govc 
sudo chmod ugo+x ./govctar/govc 
sudo mv ./govctar/govc  /usr/local/bin/govc
govc version
rm -rf ./govctar

#configure govc environment variables
echo "setting up govc environment variables"
cp govc_env_example govc_env
echo
echo "Please enter vcenter fqdn or ip address:"
read VCENTERHOST < /dev/tty
echo "Please enter vcenter username:"
read GOVC_USERNAME < /dev/tty
sed -i "s|<username>|${GOVC_USERNAME}|g" govc_env
sed -i "s|<vcenter ip or fqdn>|${VCENTERHOST}|g" govc_env

#test govc settings
echo 
echo "testing govc_env configuration"
echo
source ./govc_env
govc about
if [ $? -ne 0 ]; then
    echo "govc configuration failed, please check your govc_env file"
    exit 1
fi
echo 
echo "govc configuration successful"