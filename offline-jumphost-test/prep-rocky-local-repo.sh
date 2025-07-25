#!/bin/bash

#check if enough disk space is available
REQUIRED_SPACE=20000000 # 20GB in KB
AVAILABLE_SPACE=$(df -k / | awk 'NR==2 {print $4}')
if [ $AVAILABLE_SPACE -lt $REQUIRED_SPACE ]; then
    echo "Not enough disk space available. Required: 20GB, Available: $(($AVAILABLE_SPACE / 1024))MB"
    exit 1
fi

#Check if dvd is mounted
CHECKDEVICE=$( blkid  |grep iso |cut -d ":" -f1)
#if empty result, then throw error
if [ -z "$CHECKDEVICE" ]; then
    echo "No DVD mounted. Please mount the DVD and try again."
    exit 1
fi
#create mount point
MOUNTPOINT="/mnt/dvd"
sudo mkdir -p $MOUNTPOINT
#mount the DVD
sudo mount -o loop $CHECKDEVICE $MOUNTPOINT
#check if mount was successful
if [ $? -ne 0 ]; then
    echo "Failed to mount DVD. Please check the DVD and try again."
    exit 1
fi
#check if medie is a rocky iso but testing if  media.repo file exists
if [ ! -f $MOUNTPOINT/media.repo ]; then
    echo "Not a valid Rocky Linux DVD. Please check the DVD and try again."
    exit 1
fi

#makedir repo directory
echo "creating repo directory at $REPO_DIR"
REPO_DIR="/opt/rocky-repo"
sudo mkdir -p $REPO_DIR

#copy the contents of the DVD to the repo directory
echo "copying contents of DVD to repo directory"
sudo cp -r $MOUNTPOINT/* $REPO_DIR
#check if copy was successful
if [ $? -ne 0 ]; then
    echo "Failed to copy contents of DVD to repo directory. Please check the DVD and try again."
    exit 1
fi
#unmount the DVD
sudo umount $MOUNTPOINT
#replace rocky repo config file
#copy existing repo file to backup
sudo mkdir -p $REPO_DIR/yum.repos.d/backup
sudo mv /etc/yum.repos.d/* $REPO_DIR/yum.repos.d/backup
sudo touch /etc/yum.repos.d/rocky9.repo
#check if repo file was created successfully
if [ $? -ne 0 ]; then
    echo "Failed to create repo file. Please check the repo file and try again."
    exit 1
fi
sudo bash -c 'cat > /etc/yum.repos.d/rocky9.repo' <<EOF
[BaseOS]
name=BaseOS Packages Rocky Linux 9
metadata_expire=-1
gpgcheck=1
enabled=1
baseurl=file:///$REPO_DIR/BaseOS/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

[AppStream]
name=AppStream Packages Rocky Linux 9
metadata_expire=-1
gpgcheck=1
enabled=1
baseurl=file:///$REPO_DIR/AppStream/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

EOF
#check if repo file was replaced successfully
if [ $? -ne 0 ]; then
    echo "Failed to replace repo file. Please check the repo file and try again."
    echo "repo file backup is available at $REPO_DIR/rocky9.repo.bak"
    exit 1
fi
#clean yum cache
sudo yum clean all
sudo yum repolist enabled
sudo dnf --disablerepo="*" --enablerepo="AppStream" list available

#install tools
sudo yum install -y git tmux wget 
#check if tools were installed successfully
if [ $? -ne 0 ]; then
    echo "Failed to install tools. Please check the repo config and try again."
    exit 1
fi