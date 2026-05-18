#!/bin/bash

echo "Select Management cluster kubeconfig file:"

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
KUBECONFIG=$KUBECONFIGYAML kubectl apply -f temp-metallb.yaml

if [ $? -ne 0 ]; then
    echo "problem applying MetalLB settings. Exiting."
    exit 1
fi
echo "MetalLB configured"
echo 
echo "Checking MetalLB status"
KUBECONFIG=$KUBECONFIGYAML kubectl get IPAddressPool -A
KUBECONFIG=$KUBECONFIGYAML kubectl get L2Advertisement -A
