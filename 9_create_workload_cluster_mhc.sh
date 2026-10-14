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

echo "Generating MHC for cluster ${CLUSTER} in namespace ${CLUSTERNS}"

echo "generating Control Plane MHC"
CPMHCYAML="apiVersion: cluster.x-k8s.io/v1beta1
kind: MachineHealthCheck
metadata:
  labels:
    cluster.x-k8s.io/cluster-name: ${CLUSTER}
  name: ${CLUSTER}
  namespace: ${CLUSTERNS}
spec:
  clusterName: ${CLUSTER}
  maxUnhealthy: 40%
  nodeStartupTimeout: 10m0s
  selector:
    matchLabels:
      cluster.x-k8s.io/cluster-name: ${CLUSTER}
      cluster.x-k8s.io/control-plane: \"\"
  unhealthyConditions:
  - status: \"False\"
    timeout: 5m0s
    type: Ready
  - status: Unknown
    timeout: 5m0s
    type: Ready
  - status: \"True\"
    timeout: 5m0s
    type: MemoryPressure
  - status: \"True\"
    timeout: 5m0s
    type: DiskPressure
  - status: \"True\"
    timeout: 5m0s
    type: PIDPressure
  - status: \"True\"
    timeout: 5m0s
    type: NetworkUnavailable
"

echo "${CPMHCYAML}" > ${CLUSTER}-controlplane-mhc.yaml

echo "MHC yaml for Control Plane generated in file ${CLUSTER}-controlplane-mhc.yaml"

echo "generating Worker MHC"

#Get machineDeployment name for the cluster
CLUSTERMDS=$(kubectl get machinedeployment -n ${CLUSTERNS} --no-headers | grep ${CLUSTER} | awk '{print $1}')
if [[ -z "$CLUSTERMDS" ]]; then
    echo "No machine deployments found for cluster ${CLUSTER}. Exiting."
    exit 1
fi

for MD in $CLUSTERMDS; do
    echo "generating MHC for machine deployment ${MD}"
    MDYAML=$(kubectl get machinedeployment $MD -n ${CLUSTERNS} -oyaml)


    WKMHCYAML="apiVersion: cluster.x-k8s.io/v1beta1
kind: MachineHealthCheck
metadata:
  labels:
    cluster.x-k8s.io/cluster-name: ${CLUSTER}
  name: ${MD}
  namespace: ${CLUSTERNS}
  ownerReferences:
spec:
  clusterName: ${CLUSTER}
  maxUnhealthy: 40%
  nodeStartupTimeout: 10m0s
  selector:
    matchLabels:
      cluster.x-k8s.io/cluster-name: ${CLUSTER}
      cluster.x-k8s.io/deployment-name: ${MD}        
  unhealthyConditions:
  - status: \"False\"
    timeout: 5m0s
    type: Ready
  - status: Unknown
    timeout: 5m0s
    type: Ready
  - status: \"True\"
    timeout: 5m0s
    type: MemoryPressure
  - status: \"True\"
    timeout: 5m0s
    type: DiskPressure
  - status: \"True\"
    timeout: 5m0s
    type: PIDPressure
  - status: \"True\"
    timeout: 5m0s
    type: NetworkUnavailable
"

echo "${WKMHCYAML}" > ${MD}-workload-mhc.yaml
echo
echo "MHC yaml for machine deployment ${MD} generated in file ${MD}-workload-mhc.yaml"

done
