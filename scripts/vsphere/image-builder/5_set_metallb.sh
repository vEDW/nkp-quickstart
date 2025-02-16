#!/bin/bash

KUBECONFIGS=$(ls *.conf)
select KUBECONFIG in $KUBECONFIGS; do
    test=$(KUBECONFIG=$KUBECONFIG kubectl get nodes)
    if [ $? -ne 0 ]; then
        echo "KUBECONFIG $KUBECONFIG is not valid. Exiting."
        exit 1
    fi
    echo "you selected kubeconfig : ${KUBECONFIG}"
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
KUBECONFIG=$KUBECONFIG kubectl apply -f temp-metallb.yaml

if [ $? -ne 0 ]; then
    echo "problem applying MetalLB settings. Exiting."
    exit 1
fi
echo "MetalLB configured"
