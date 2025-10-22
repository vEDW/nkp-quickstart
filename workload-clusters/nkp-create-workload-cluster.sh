#!/bin/bash

#function
randgen(){
    cat /dev/urandom | tr -dc 'a-z0-9' | head -c 5; echo
}

#check if cluster-env file exists
if [ ! -f ./cluster-env ]; then
    echo "cluster-env file not found. Please create it with the required variables by cloning cluster-env.example."
    exit 1
fi
source ./cluster-env

#select NKP Management Cluster kubeconfig context
CONTEXTS=$(kubectl config get-contexts --output=name)
#count number of contexts
NUM_CONTEXTS=$(echo "$CONTEXTS" | wc -l)
if [ "$NUM_CONTEXTS" -eq 0 ]; then
    echo "No kubeconfig contexts found. Please configure your kubeconfig."
    exit 1
elif [ "$NUM_CONTEXTS" -eq 1 ]; then
    CLUSTERCTX="$CONTEXTS"
    echo "Only one kubeconfig context found. Using context: $CLUSTERCTX"
else
    echo "Multiple kubeconfig contexts found."
    echo
    echo "Select management cluster or CTRL-C to quit"
    select CONTEXT in $CONTEXTS; do 
        echo "you selected cluster context : ${CONTEXT}"
        echo 
        CLUSTERCTX="${CONTEXT}"
        break
    done

    kubectl config use-context $CLUSTERCTX
fi

#check if current context is set to the management cluster
CAPICRD=$(kubectl  api-resources |grep cluster.x-k8s.io)
if [[ -z "$CAPICRD" ]]; then
    echo "The current kubeconfig context is not a NKP Management Cluster."
    exit 1
fi

#check NKP edition
LICENSECRD=$(kubectl get licenses -n kommander -o json |jq -r '.items[].status.dkpLevel')
#check if license is empty
if [[ -z "$LICENSECRD" ]]; then
    echo "No license found. Please check if the license is installed."
    LICENSECRD="No License found"
    exit 1
else
    echo
    echo "NKP Edition: $LICENSECRD"
    echo
    if [[ "$LICENSECRD" == "Ultimate" ]]; then
        #select workspace in which to create the workload cluster
        WORKSPACES=$(kubectl get workspaces -o jsonpath="{.items[*].metadata.name}")
        echo
        echo "Select workspace in which to create the workload cluster or CTRL-C to quit"
        select WORKSPACE in $WORKSPACES; do 
            echo "you selected workspace : ${WORKSPACE}"
            echo 
            break
        done
        #get workspace namespace
        WORKSPACE_NAMESPACE=$(kubectl get workspace $WORKSPACE -o jsonpath="{.spec.namespaceName}")

    # else
    #     echo
    #     echo "generating random namespace for workload cluster"
    #     WORKSPACE="$CLUSTER_NAME-$(randgen)"
    #     WORKSPACE_NAMESPACE="$WORKSPACE-$(randgen)"
    fi
fi


nkp create cluster nutanix -c $CLUSTER_NAME \
    ${CLUSTER_HOSTNAME:+--cluster-hostname "$CLUSTER_HOSTNAME"} \
    --endpoint https://$NUTANIX_ENDPOINT:$NUTANIX_PORT \
    --insecure \
    --kubernetes-service-load-balancer-ip-range $LB_IP_RANGE \
    --control-plane-endpoint-ip $CONTROL_PLANE_ENDPOINT_IP \
    --control-plane-vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --control-plane-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --control-plane-subnets $NUTANIX_SUBNET_NAME \
    --control-plane-replicas $CONTROL_PLANE_REPLICAS \
    --worker-vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --worker-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --worker-subnets $NUTANIX_SUBNET_NAME \
    --worker-replicas $WORKER_NODES_REPLICAS \
    --csi-storage-container $NUTANIX_STORAGE_CONTAINER_NAME \
    --csi-hypervisor-attached-volumes=$CSI_HYPERVISOR_ATTACHED \
    ${SSH_PUBLIC_KEY_FILE:+--ssh-public-key-file "$SSH_PUBLIC_KEY_FILE"} \
    ${REGISTRY_MIRROR_URL:+--registry-mirror-url https://"$REGISTRY_MIRROR_URL"} \
    ${REGISTRY_MIRROR_USERNAME:+--registry-mirror-username "$REGISTRY_MIRROR_USERNAME"} \
    ${REGISTRY_MIRROR_PASSWORD:+--registry-mirror-password "$REGISTRY_MIRROR_PASSWORD"} \
    ${REGISTRY_URL:+--registry-url https://"$REGISTRY_URL"} \
    ${REGISTRY_USERNAME:+--registry-username "$REGISTRY_USERNAME"} \
    ${REGISTRY_PASSWORD:+--registry-password "$REGISTRY_PASSWORD"} \
    ${CP_CATEGORIES:+--control-plane-pc-categories "$CP_CATEGORIES"} \
    ${WORKER_CATEGORIES:+--worker-pc-categories "$WORKER_CATEGORIES"} \
    ${WORKSPACE_NAMESPACE:+-n "$WORKSPACE_NAMESPACE"} \
    ${SKIP_PREFLIGHT_CHECKS:+--skip-preflight-checks "$SKIP_PREFLIGHT_CHECKS"} \
    --dry-run -o yaml > $CLUSTER_NAME.yaml

if [ $? -ne 0 ]; then
    echo "Cluster creation failed. Please check the parameters in cluster-env."
    exit 1
else
    echo "Cluster definition created:  $CLUSTER_NAME.yaml"
    echo
    echo "to execute, run : kubectl apply -f $CLUSTER_NAME.yaml --server-side=true"
fi