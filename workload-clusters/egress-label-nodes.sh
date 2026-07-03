#!/bin/bash

CONTEXTS=$(kubectl config get-contexts --output=name)
echo
echo "Select workload cluster or CTRL-C to quit"
select CONTEXT in $CONTEXTS; do 
    echo "you selected cluster context : ${CONTEXT}"
    echo 
    CLUSTERCTX="${CONTEXT}"
    break
done

kubectl config use-context $CLUSTERCTX


WORKERNODES=$(kubectl get nodes --no-headers |grep -v control-plane |awk '{print $1}')
WORKERNODESCOUNT=$(echo "$WORKERNODES" |wc -l)
if [ $WORKERNODESCOUNT -eq 0 ]; then
    echo "No worker nodes found in the selected cluster context. Exiting."
    exit 1
fi
echo "labeling $WORKERNODESCOUNT worker nodes with egress label"
echo "Press Enter to continue or CTRL-C to quit"
read

for NODE in $WORKERNODES; do
    kubectl label node $NODE k8s.ovn.org/egress-assignable=""
    if [ $? -ne 0 ]; then
        echo "labeling node $NODE failed. Exiting."
        exit 1
    fi
done

echo "Worker Nodes labeled with egress label successfully."
echo
#check nodes for egress label
LABELED_NODES=$(kubectl get nodes -l k8s.ovn.org/egress-assignable --no-headers |awk '{print $1}')
LABELED_NODESCOUNT=$(echo "$LABELED_NODES" |wc -l)
if [ $LABELED_NODESCOUNT -eq 0 ]; then
    echo "No nodes found with egress label. Exiting."
    exit 1
fi
echo "Nodes with egress label:"
for NODE in $LABELED_NODES; do
    echo " - $NODE"
done
