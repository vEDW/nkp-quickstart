#!/bin/bash

echo "this is work in progress - don't use it yet"

get_nkp_cluster_registry_mirror() {
    # Function to check if the cluster has registry mirror, internal mirror or nothing
    CLUSTER_NAME="$1"
    CLUSTERNAMESPACE="$2"

    #check if internal registry
    INTERNALMIRROR=$(kubectl get clusters.cluster.x-k8s.io $CLUSTER_NAME -n $CLUSTERNAMESPACE -o jsonpath='{.spec.topology.variables[].value.addons.registry.provider}')
    if [[ "$INTERNALMIRROR" == "CNCF Distribution" ]]; then
        echo "internal registry mirror"
    else
        #check if registry mirror
        REGISTRYMIRROR=$(kubectl get clusters.cluster.x-k8s.io $CLUSTER_NAME -n $CLUSTERNAMESPACE -o jsonpath='{.spec.topology.variables[].value.globalImageRegistryMirror.url}')
        if [[ -z "$REGISTRYMIRROR" ]]; then
            echo "no registry mirror"
        else
            echo "Global registry mirror : $REGISTRYMIRROR"
        fi
    fi
}
get_nkp_clusterprivate_registries() {
    # Function to check if the cluster has registry mirror, internal mirror or nothing
    CLUSTER_NAME="$1"
    CLUSTERNAMESPACE="$2"
    #check if internal registry
    PRIVATEREGISTRIES=$(kubectl get clusters.cluster.x-k8s.io $CLUSTER_NAME -n $CLUSTERNAMESPACE -o jsonpath='{.spec.topology.variables[].value.imageRegistries[].url}')
    if [[ -z "$PRIVATEREGISTRIES" ]]; then
        echo "no private registries"
    else
        echo "Private registries : $PRIVATEREGISTRIES"
    fi
}

CONTEXTS=$(kubectl config get-contexts --output=name)
echo
echo "Select management cluster to list clusters or CTRL-C to quit"
select CONTEXT in $CONTEXTS; do 
    echo "you selected cluster context : ${CONTEXT}"
    echo 
    CLUSTERCTX="${CONTEXT}"
    break
done

kubectl config use-context $CLUSTERCTX
if [ $? -ne 0 ]; then
    echo "kubectl context error. Exiting."
    exit 1
fi

#check if this is a NKP Management cluster
KOMANDERCRD=$(kubectl  api-resources |grep cluster.x-k8s.io)
if [[ -z "$KOMANDERCRD" ]]; then
    echo "This is not a NKP Management Cluster. Please select a valid management cluster."
    exit 1
fi

CLUSTERFULLLIST=$(kubectl get clusters.cluster.x-k8s.io -A)
CLUSTERLIST=$(echo "$CLUSTERFULLLIST" | awk 'NR>1 {print $2}')
echo "Clusters"
for CLUSTERNAME in ${CLUSTERLIST}; do
    CLUSTERNS=$(echo "$CLUSTERFULLLIST" | grep " $CLUSTERNAME " | awk '{print $1}')
    echo "|"
    echo "|_ $CLUSTERNAME"
    echo "|    |"
    REGMIRROR=$(get_nkp_cluster_registry_mirror $CLUSTERNAME $CLUSTERNS)
    echo "|    |___ Registry Mirror: $REGMIRROR"
    #check private registries
    PRIVATEREGISTRIES=$(get_nkp_clusterprivate_registries $CLUSTERNAME $CLUSTERNS)
    echo "|    |"
    echo "|    |___ Private Registries: $PRIVATEREGISTRIES"
done


#select cluster to modify
echo
echo "Select cluster to reconfigure registry mirror or CTRL-C to quit" 
select CLUSTER in $CLUSTERLIST; do 
    echo "you selected cluster : ${CLUSTER}"
    CLUSTERNAME="${CLUSTER}"
    CLUSTERNAMESPACE=$(echo "$CLUSTERFULLLIST" | grep " $CLUSTERNAME " | awk '{print $1}')
    break
done

#get new registry mirror info
echo "Enter new registry mirror URL or CTRL-C to quit : "
read REGISTRYMIRROR

#test provided URL
if ! curl -f -s "$REGISTRYMIRROR" > /dev/null; then
    echo "Registry mirror URL is not accessible. Please check the URL and try again."
    exit 1
fi

#check if cluster has registry mirror or private registry
INTERNALMIRROR=$(kubectl get clusters.cluster.x-k8s.io $CLUSTERNAME -n $CLUSTERNAMESPACE -o jsonpath='{.spec.topology.variables[].value.addons.registry.provider}')
if [[ "$INTERNALMIRROR" == "CNCF Distribution" ]]; then
    REMOVE_INTERNAL_REGISTRY_CONFIRMED=false
    echo "Cluster has internal registry mirror."
    echo "press enter to remove internal registry mirror and add new registry mirror or CTRL-C to quit"
    read
    REMOVE_INTERNAL_REGISTRY_CONFIRMED=true
fi 
#Check if cluster has registry mirror
REGISTRYMIRROR=$(kubectl get clusters.cluster.x-k8s.io $CLUSTERNAME -n $CLUSTERNAMESPACE -o jsonpath='{.spec.topology.variables[].value.globalImageRegistryMirror.url}')
if [[ -z "$REGISTRYMIRROR" ]]; then
    echo "Cluster has no registry mirror yet."
else
    echo "Cluster has registry mirror : $REGISTRYMIRROR."
    echo "press enter to remove existing registry mirror and add new registry mirror or CTRL-C to quit"
    read
    REMOVE_REGISTRY_MIRROR_CONFIRMED=true
fi
CLUSTER_YAML=$(kubectl get clusters.cluster.x-k8s.io $CLUSTERNAME -n $CLUSTERNAMESPACE -o yaml)
if [[ "$REMOVE_INTERNAL_REGISTRY_CONFIRMED" == true ]]; then
    CLUSTER_YAML=$(echo "$CLUSTER_YAML" | yq 'del(.spec.topology.variables[] | select(.value.addons.registry.provider == "CNCF Distribution"))')
fi
if [[ "$REMOVE_REGISTRY_MIRROR_CONFIRMED" == true ]]; then
    CLUSTER_YAML=$(echo "$CLUSTER_YAML" | yq 'del(.spec.topology.variables[] | select(.value.globalImageRegistryMirror.url != null))')
fi
#add new registry mirror
CLUSTER_YAML=$(echo "$CLUSTER_YAML" | yq '.spec.topology.variables += {"name": "globalImageRegistryMirror", "value": {"url": "'$REGISTRYMIRROR'"}}')
echo "$CLUSTER_YAML" > $CLUSTERNAME-updated.yaml
echo "Updated cluster yaml with new registry mirror. to apply changes run : kubectl apply -f $CLUSTERNAME-updated.yaml"
