#!/bin/bash

CONTEXTS=$(kubectl config get-contexts  --no-headers=true |rev | awk '{print $4}' |rev)
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

CLUSTERSJSON=$(kubectl get cluster -A -ojson |jq -r '.items[]|select (.metadata.labels."konvoy.d2iq.io/provider" == "nutanix") |.')
echo $CLUSTERSJSON | jq . > clusters.json
CLUSTERLIST=$(echo "${CLUSTERSJSON}"| jq -r '.metadata.name')
echo ${CLUSTERLIST} > clusterlist.json
echo "Clusters"
echo "|"

for CLUSTERNAME in ${CLUSTERLIST}; do
    echo "|_ $CLUSTERNAME"
    echo "|    |"
    VLAN=$(echo $CLUSTERSJSON |jq -r --arg CLUSTER $CLUSTERNAME '.|select (.metadata.name == $CLUSTER) |.spec.topology.variables[].value.controlPlane.nutanix.machineDetails.subnets[].name')
    #.spec.topology.variables[].controlPlane.subnets[].name
    echo "|    |___ CP VLAN: $VLAN"
    VLAN=$(echo $CLUSTERSJSON |jq -r --arg CLUSTER $CLUSTERNAME '.|select (.metadata.name == $CLUSTER) |"API VIP: " + .spec.controlPlaneEndpoint.host')
    echo "|    |               |___ $VLAN"
    echo "|    |"
    VLAN=$(echo $CLUSTERSJSON |jq -r --arg CLUSTER $CLUSTERNAME '.|select (.metadata.name == $CLUSTER) |.spec.topology.workers.machineDeployments[]|.name + " - " + .variables.overrides[].value.nutanix.machineDetails.subnets[].name')
    #.spec.topology.variables[].controlPlane.subnets[].name
    echo "|    |___ Node Pool VLAN: $VLAN"
    VLAN=$(echo $CLUSTERSJSON |jq -r --arg CLUSTER $CLUSTERNAME '.|select (.metadata.name == $CLUSTER) |["LB Range: " + (.spec.topology.variables[].value.addons.serviceLoadBalancer.configuration.addressRanges[].start + "-" + .spec.topology.variables[].value.addons.serviceLoadBalancer.configuration.addressRanges[].end )]|@tsv')
    echo "|                                    |___ $VLAN"
done