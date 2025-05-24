#!/bin/bash

echo "Select workload cluster kubeconfig context:"

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
kubectl apply -f temp-metallb.yaml

if [ $? -ne 0 ]; then
    echo "problem applying MetalLB settings. Exiting."
    exit 1
fi
echo "MetalLB configured"
echo 
echo "Checking MetalLB status"
kubectl get IPAddressPool -A
kubectl get L2Advertisement -A
