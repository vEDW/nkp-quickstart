#!/bin/bash

# This script is used to get a support bundle from a workload cluster using the nkp CLI.

#check if nkp cli is installed
if ! command -v nkp &> /dev/null
then
    echo "nkp not found - please install nkp cli - see nkp-quickstart/scripts/get-nkp-cli"
    exit
fi


CONTEXTS=$(kubectl config get-contexts --output=name)
#check if at least one context is available
if [ -z "$CONTEXTS" ]; then
    echo "No kubernetes contexts found. Exiting."
    exit 1
fi

echo
echo "Select NKP Management cluster or CTRL-C to quit"
select CONTEXT in $CONTEXTS; do 
    echo "you selected cluster context : ${CONTEXT}"
    echo 
    CLUSTERCTX="${CONTEXT}"
    break
done

kubectl config use-context $CLUSTERCTX

# check if management cluster

KOMANDERCRD=$(kubectl  api-resources |grep cluster.x-k8s.io)
if [[ -z "$KOMANDERCRD" ]]; then
    echo "This is not a NKP Management Cluster. Please select a valid management cluster."
    exit 1
fi

# List all workload clusters
WORKLOAD_CLUSTERS=$(kubectl get clusters.cluster.x-k8s.io -A -o jsonpath='{.items[*].metadata.name}')

# select workload cluster to diagnose
WORKLOADCLUSTERSJSON=$(kubectl get clusters.cluster.x-k8s.io -A -o json)
WORKLOADCLUSTERS=$(echo "${WORKLOADCLUSTERSJSON}" | jq -r '.items[].metadata|select(.namespace != "default")|.name')
#check if workload clusters are found
if [[ -z "$WORKLOADCLUSTERS" ]]; then
    echo
    echo "No workload clusters found."
else
    echo
    echo "Select Workload Cluster to diagnose or CTRL-C to quit"
    echo
    select WKCLUSTER in $WORKLOADCLUSTERS; do 
        CLUSTERNAMESPACE=$(echo "${WORKLOADCLUSTERSJSON}" | jq --arg WKCLUSTER "$WKCLUSTER" -r '.items[].metadata |select (.name ==  $WKCLUSTER) |.namespace')
        echo "you selected workload cluster : ${WKCLUSTER} in namespace ${CLUSTERNAMESPACE}"
        echo 
        break
    done
    #get kubeconfig for workload cluster
    KUBECONFIGYAML=$(nkp get kubeconfig --cluster-name $WKCLUSTER --namespace $CLUSTERNAMESPACE)
    #check if kubeconfig was retrieved successfully
    if [[ -z "$KUBECONFIGYAML" ]]; then
        echo "Failed to retrieve kubeconfig for workload cluster: $WKCLUSTER"
        exit 1
    fi
    #write kubeconfig to file
    KUBECONFIG_FILE="/tmp/kubeconfig-${WKCLUSTER}.yaml"
    echo "$KUBECONFIGYAML" > $KUBECONFIG_FILE
    echo "Kubeconfig for workload cluster $WKCLUSTER written to $KUBECONFIG_FILE"
    #set KUBECONFIG environment variable
    export KUBECONFIG=$KUBECONFIG_FILE
    #Get support bundle
    nkp diagnose --bundle-name-prefix "${WKCLUSTER}-"
    #check if nkp diagnose was successful
    if [ $? -ne 0 ]; then
        echo "nkp diagnose failed. Exiting."
        exit 1
    fi
    echo "nkp diagnose completed successfully"
    #remove kubeconfig file
    rm -f $KUBECONFIG_FILE
    echo "Kubeconfig file $KUBECONFIG_FILE deleted"
fi

