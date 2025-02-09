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