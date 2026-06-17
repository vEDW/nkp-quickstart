#!/bin/bash

echo "Select Management Cluster : "

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


echo "Select namespace to clean up : "
TERMINATINGNSS=$(KUBECONFIG=$KUBECONFIGYAML kubectl  get ns | grep Terminating | awk '{print $1}')
select TERMINATINGNS in $TERMINATINGNSS; do
    echo "you selected namespace : ${TERMINATINGNS}"
    echo
    break
done

RESOURCES=$(KUBECONFIG=$KUBECONFIGYAML kubectl api-resources --verbs=list --namespaced -o name)
for type in $RESOURCES; do
    KUBECONFIG=$KUBECONFIGYAML kubectl get "$type" -n "$TERMINATINGNS" --no-headers 2>/dev/null | awk '{print $1}' | while read res; do
        echo "Removing finalizer for $type/$res..."
        KUBECONFIG=$KUBECONFIGYAML kubectl patch "$type" "$res" -n "$TERMINATINGNS" --type=merge -p '{"metadata":{"finalizers":null}}'
    done
done

