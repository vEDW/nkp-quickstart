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
echo "Select workload cluster to get kubeconfig or CTRL-C to quit"
select CLUSTER in $CLUSTERS; do 
    CLUSTERNS=$(kubectl get cluster --no-headers -A |grep ${CLUSTER} | awk '{print $1}')
    echo "you selected cluster  : ${CLUSTER} in namespace : ${CLUSTERNS}"
    echo 
    break
done

CLUSTERKUBEYAML="${CLUSTER}.conf"
nkp get kubeconfig -c ${CLUSTER} -n ${CLUSTERNS} > $CLUSTERKUBEYAML
if [ $? -ne 0 ]; then
    echo "get kubeconfig failed. Exiting."
    exit 1
fi


echo "Enter ip range for metallb"
read METALLB_IP_RANGE

METALYAML="apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - ${METALLB_IP_RANGE}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default
"
echo "$METALYAML" > temp-metallb.yaml
KUBECONFIG=$CLUSTERKUBEYAML kubectl apply -f temp-metallb.yaml

if [ $? -ne 0 ]; then
    echo "problem applying MetalLB settings. Exiting."
    exit 1
fi
echo "MetalLB configured"
echo 
echo "Checking MetalLB status"
KUBECONFIG=$CLUSTERKUBEYAML kubectl get IPAddressPool -A
KUBECONFIG=$CLUSTERKUBEYAML kubectl get L2Advertisement -A
