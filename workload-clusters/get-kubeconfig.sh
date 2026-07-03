#!/bin/bash


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

CLUSTERS=$(kubectl get cluster --no-headers -A |awk '{print $2}')
echo
echo "Select workload cluster to get kubeconfig or CTRL-C to quit"
select CLUSTER in $CLUSTERS; do 
    CLUSTERNS=$(kubectl get cluster --no-headers -A |grep ${CLUSTER} | awk '{print $1}')
    echo "you selected cluster  : ${CLUSTER} in namespace : ${CLUSTERNS}"
    echo 
    break
done

nkp get kubeconfig -c ${CLUSTER} -n ${CLUSTERNS} > ${CLUSTER}.conf
if [ $? -ne 0 ]; then
    echo "get kubeconfig failed. Exiting."
    exit 1
fi

echo "kubeconfig file created : ${CLUSTER}.conf"