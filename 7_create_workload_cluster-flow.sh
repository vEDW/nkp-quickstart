#!/bin/bash

source ./nkp-env


echo "Select Management Cluster : "

KUBECONFIGS=$(ls *.conf)
select KUBECONFIGYAML in $KUBECONFIGS; do
    test=$(KUBECONFIG=$KUBECONFIGYAML kubectl get nodes)
    if [ $? -ne 0 ]; then
        echo "KUBECONFIG $KUBECONFIGYAML is not valid. Exiting."
        exit 1
    fi
    echo "you selected kubeconfig : ${KUBECONFIGYAML}"
    echo
    break
done


echo "Enter name for NKP Workload Cluster : "
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
#SAVEIFS=$IFS
#IFS=$(echo -en "\n\b")
#VMSLIST=$(govc find $GOVC_DATACENTER -type m |xargs govc vm.info -json  |jq -r '.virtualMachines[]|select (.config.template == true ) |.name')
VMSLIST=$(govc find $GOVC_DATACENTER -type m |grep "nkp-ubuntu-")
select template in $VMSLIST; do
#    template=$(echo $template | sed "s#$GOVC_DATACENTER/vm/##")
    echo "you selected template : ${template}"
    echo
    break
done

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
DATASTORES=$(govc find / -type Datastore )
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
echo "Select VM Folder :"
select FOLDER in $FOLDERS; do 
    echo "you selected VM Folder : ${FOLDER}"
    echo 
    break
done

RESOURCEPOOLS=$(govc find / -type ResourcePool)
echo
echo "Select Resource Pool to set as default"
select RESOURCEPOOL in $RESOURCEPOOLS; do 
    echo "you selected Resource Pool : ${RESOURCEPOOL}"
    echo 
    export GOVC_RESOURCE_POOL="${RESOURCEPOOL}"
    break
done
RESOURCE_POOL=$(echo "${GOVC_RESOURCE_POOL}" )
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
export VSPHERE_USERNAME=$(govc env |grep USERNAME | cut -d "=" -f 2)
export VSPHERE_PASSWORD=$(govc env |grep PASSWORD | cut -d "=" -f 2)
#get vcenter thumbprint
VCENTERTP=$(echo | openssl s_client -connect $VSPHERE_SERVER:443 2>/dev/null | openssl x509 -noout -fingerprint -sha256 | cut -d "=" -f2)

KUBECONFIG=$KUBECONFIGYAML nkp create cluster vsphere \
  --cluster-name ${NKPCLUSTER} \
  --network ${GOVC_NETWORK} \
  --control-plane-endpoint-host ${NKPCLUSTERVIP} \
  --data-center ${GOVC_DATACENTER} \
  --data-store ${GOVC_DATASTORE} \
  --folder "${FOLDER}" \
  --server ${VSPHERE_SERVER} \
  --ssh-public-key-file ${LOCALKEY} \
  --resource-pool ${GOVC_RESOURCE_POOL} \
  --vm-template ${template} \
  --virtual-ip-interface "eth0" \
  --kubernetes-pod-network-cidr "${POD_CIDR}" \
  --tls-thumb-print "${VCENTERTP}" \
  --control-plane-replicas 1 \
  --worker-memory 16 \
  --worker-replicas 2 \
  ${REGISTRY_MIRROR_URL:+--registry-mirror-url https://"$REGISTRY_MIRROR_URL"} \
  ${REGISTRY_MIRROR_USERNAME:+--registry-mirror-username "$REGISTRY_MIRROR_USERNAME"} \
  ${REGISTRY_MIRROR_PASSWORD:+--registry-mirror-password "$REGISTRY_MIRROR_PASSWORD"} \
  ${REGISTRY_MIRROR_CA_CERT_FILE:+--registry-mirror-cacert "$REGISTRY_MIRROR_CA_CERT_FILE"} \
  ${SSH_KEYFILE_PATH:+--ssh-public-key-file "$SSH_KEYFILE_PATH"} \
  --dry-run -o yaml > $NKPCLUSTER.yaml

# Remove calico entries

yq e 'del(select(.metadata.name | test("calico|tigera")))' $NKPCLUSTER.yaml > $NKPCLUSTER-no-calico-labels.yaml
#yq -i 'select((.metadata.name // "") | test("tigera|calico-cni-installation") | not)' "{{ env.cluster_name }}-config/deploy-{{ env.cluster_name }}.yaml"

yq e '(select(.kind == "Cluster") | del(.metadata.labels."konvoy.d2iq.io/cni")) // select(.kind != "Cluster")' $NKPCLUSTER-no-calico-labels.yaml > $NKPCLUSTER-flow-cni.yaml

WORKSPACE_NAMESPACE=$(yq e 'select(.kind == "Namespace")|.metadata.name' $NKPCLUSTER-flow-cni.yaml)
POD_CIDR=$(yq e 'select(.kind == "Cluster")|.spec.clusterNetwork.pods.cidrBlocks[0]' $NKPCLUSTER-flow-cni.yaml)
SERVICE_CIDR=$(yq e 'select(.kind == "Cluster")|.spec.clusterNetwork.services.cidrBlocks[0]' $NKPCLUSTER-flow-cni.yaml)
FLOWYAML="---
apiVersion: addons.cluster.x-k8s.io/v1alpha1
kind: HelmChartProxy
metadata:
  name: flow-cni
  namespace: ${WORKSPACE_NAMESPACE}
spec:
  clusterSelector:
    matchLabels:
      konvoy.d2iq.io/cluster-name: ${NKPCLUSTER}
  repoURL: oci://${FLOWREGISTRY}
  chartName: nutanix-flow-cni
  version: ${FLOW_CHART_VERSION}
  namespace: flow-cni-system
  tlsConfig:
    insecureSkipTLSVerify: true
  options:
    waitForJobs: true
    wait: true
    timeout: 30m
    install:
      createNamespace: true
  valuesTemplate: |
    nutanix-core-flow-ovn-kubernetes:
      k8sAPIServer: "https://${NKPCLUSTERVIP}:6443" 
      podNetwork: \"${POD_CIDR}/24\" 
      serviceNetwork: \"${SERVICE_CIDR}\"
      ovs-node:
        enabled: false
    nutanix-core-flow-container-security:
      image:
        repository: ${FLOWREGISTRY}/flow-cns-cilium
        tag: \"${FLOW_CNS_CILIUM_TAG}\"
    image:
        repository: ${FLOWREGISTRY}/flow-k8s-cni
        tag: \"${FLOW_K8S_CNI_TAG}\"
    global:
      runOvsOnNode: true
      enableEgressIp: true
      enableEgressService: true
      image:
        repository: ${FLOWREGISTRY}/flow-ovn-kubernetes
        tag: \"${FLOW_OVN_KUBERNETES_TAG}\"
"

echo "$FLOWYAML" > $NKPCLUSTER-flow-hcp.yaml
#wait for namespace deletion
echo "Waiting for  namespace to be deleted..."
kubectl --kubeconfig=$KUBECONFIGYAML  delete ns $WORKSPACE_NAMESPACE --wait=true


echo "Cluster yaml created. to deploy cluster run : KUBECONFIG=$KUBECONFIGYAML kubectl apply -f $NKPCLUSTER-flow-cni.yaml --server-side=true"
