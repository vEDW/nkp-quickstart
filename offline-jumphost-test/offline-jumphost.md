# How to create full offline jumphost

## Download software

using internet connected station:
* import NKP rocky image from download portal
* import Rocky linux DVD iso
    * https://rockylinux.org/download : https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9.5-x86_64-dvd.iso
* download https://download.docker.com/linux/static/stable/x86_64/docker-28.0.1.tgz 
* download https://github.com/mikefarah/yq/releases/download/v4.45.2/yq_linux_amd64.tar.gz

## Build offline jumphost

Create offline VM
* create VM with cloud-init - see: [cloud-init](./cloud-init)
* copy docker-*.tgz to jumphost
* copy airgap bundle to jumphost
* mount Rocky DVD iso to VM
* copy and run script : [prep-rocky-local-repo.sh](./prep-rocky-local-repo.sh)
