#!/bin/bash

echo "Select Management cluster kubeconfig context:"

#select NKP Management Cluster kubeconfig context
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

#select workload cluster on which to enable cluster autoscaler
Echo "Select Workload cluster"

CLUSTERS=$(kubectl get cluster --no-headers -A |awk '{print $2}')
select CLUSTER in $CLUSTERS; do 
    echo "you selected cluster context : ${CLUSTER}"
    echo 
    break
done

#Get cluster namespace
CLUSTERNS=$(kubectl get cluster --no-headers -A |grep ${CLUSTER} |awk '{print $1}')

#select Nodepool to enable cluster autoscaler
echo "Select Nodepool to enable cluster autoscaler"
NODEPOOLS=$(kubectl get md  --no-headers -A |grep ${CLUSTER} |awk '{print $2}')
select NODEPOOL in $NODEPOOLS; do 
    echo "you selected nodepool : ${NODEPOOL}"
    echo 
    break
done
CURRENT_NODES=$(kubectl get md  --no-headers -A |grep ${CLUSTER} |awk '{print $4}')
echo "Enter min nodes for cluster autoscaler (currently : $CURRENT_NODES nodes) "
read -e -i "${CURRENT_NODES}" MIN_NODES 
echo "Enter max nodes for cluster autoscaler"
read MAX_NODES
if [[ "$MIN_NODES" == "" ]]; then
    echo "MIN nodes is empty. Exiting."
    exit 1
fi
if [[ "$MAX_NODES" == "" ]]; then
    echo "MAX nodes is empty. Exiting."
    exit 1
fi
if [[ "$MIN_NODES" -gt "$MAX_NODES" ]]; then
    echo "MIN nodes cannot be greater than MAX nodes. Exiting."
    exit 1
fi
if [[ "$MIN_NODES" -lt 0 ]]; then
    echo "MIN nodes cannot be less than 0. Exiting."
    exit 1
fi
if [[ "$MAX_NODES" -lt 0 ]]; then
    echo "MAX nodes cannot be less than 0. Exiting."
    exit 1
fi
kubectl annotate --overwrite md ${NODEPOOL} -n ${CLUSTERNS} "cluster.x-k8s.io/cluster-api-autoscaler-node-group-min-size"="$MIN_NODES"  
if [ $? -ne 0 ]; then
    echo "problem applying cluster autoscaler min settings. Exiting."
    exit 1
fi
kubectl annotate --overwrite md ${NODEPOOL} -n ${CLUSTERNS} "cluster.x-k8s.io/cluster-api-autoscaler-node-group-max-size"="$MAX_NODES"
if [ $? -ne 0 ]; then
    echo "problem applying cluster autoscaler max settings. Exiting."
    exit 1
fi
echo "Cluster autoscaler configured"