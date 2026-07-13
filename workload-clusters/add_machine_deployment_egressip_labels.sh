#!/bin/bash

echo "Select Management cluster kubeconfig file:"

CONTEXTS=$(kubectl config get-contexts --output=name)
echo
echo "Select management cluster or CTRL-C to quit"
select CONTEXT in $CONTEXTS; do 
    echo "you selected cluster context : ${CONTEXT}"
    echo 
    CLUSTERCTX="${CONTEXT}"
    break
done

kubectl config use-context $CLUSTERCTX

#check if this is a NKP Management cluster
KOMANDERCRD=$(kubectl  api-resources |grep cluster.x-k8s.io)
if [[ -z "$KOMANDERCRD" ]]; then
    echo "This is not a NKP Management Cluster. Please select a valid management cluster."
    exit 1
fi

CLUSTERS=$(kubectl get cluster --no-headers -A |awk '{print $2}')
echo
echo "Select workload cluster or CTRL-C to quit"
select CLUSTER in $CLUSTERS; do 
    CLUSTERNS=$(kubectl get cluster --no-headers -A |grep ${CLUSTER} | awk '{print $1}')
    echo "you selected cluster  : ${CLUSTER} in namespace : ${CLUSTERNS}"
    echo 
    break
done

#Get machineDeployment name for the cluster
CLUSTERMDS=$(kubectl get machinedeployment -n ${CLUSTERNS} --no-headers | grep ${CLUSTER} | awk '{print $1}')
if [[ -z "$CLUSTERMDS" ]]; then
    echo "No machine deployments found for cluster ${CLUSTER}. Exiting."
    exit 1
fi

echo
echo "Select workload cluster MD to enable EgressIP or CTRL-C to quit"
select MD in $CLUSTERMDS; do 
    echo "you selected machine deployment  : ${MD} in namespace : ${CLUSTERNS}"
    echo 
    break
done

kubectl patch machinedeployment ${MD} -n ${CLUSTERNS}  --type='merge'  -p '{"spec":{"template":{"metadata":{"labels":{"node.cluster.x-k8s.io/egress-assignable":""}}}}}'