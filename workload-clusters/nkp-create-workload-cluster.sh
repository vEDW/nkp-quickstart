#!/bin/bash

#check if cluster-env file exists
if [ ! -f ./cluster-env ]; then
    echo "cluster-env file not found. Please create it with the required variables by cloning cluster-env.example."
    exit 1
fi
source ./cluster-env

# check if DOCKER_FLOW_TOKEN is set
if [ -z "$DOCKER_FLOW_TOKEN" ]; then
    echo "DOCKER_FLOW_TOKEN is not set. Please set it in cluster-env to pull Flow-CNI images from Docker Hub."
    exit 1
fi 


nkp create cluster nutanix -c $CLUSTER_NAME \
    --endpoint https://$NUTANIX_ENDPOINT:$NUTANIX_PORT \
    --insecure \
    --kubernetes-service-load-balancer-ip-range $LB_IP_RANGE \
    --control-plane-endpoint-ip $CONTROL_PLANE_ENDPOINT_IP \
    --control-plane-vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --control-plane-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --control-plane-subnets $NUTANIX_SUBNET_NAME \
    ${CONTROL_PLANE_REPLICAS:+--control-plane-replicas "$CONTROL_PLANE_REPLICAS"} \
    --worker-vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --worker-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --worker-subnets $NUTANIX_SUBNET_NAME \
    ${WORKER_NODES_REPLICAS:+--worker-replicas "$WORKER_NODES_REPLICAS"} \
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
    ${NUTANIX_PC_PROJECT_NAME:+--control-plane-pc-project "$NUTANIX_PC_PROJECT_NAME"} \
    ${NUTANIX_PC_PROJECT_NAME:+--worker-pc-project "$NUTANIX_PC_PROJECT_NAME"} \
    ${WORKSPACE_NAMESPACE:+-n "$WORKSPACE_NAMESPACE"} \
    ${SKIP_PREFLIGHT_CHECKS:+--skip-preflight-checks "$SKIP_PREFLIGHT_CHECKS"} \
    ${NTPSERVERS:+--ntp-servers "$NTPSERVERS"} \
    --kubernetes-pod-network-cidr ${POD_CIDR} \
    --kubernetes-service-cidr ${SERVICE_CIDR} \
    --dry-run -o yaml > $CLUSTER_NAME.yaml

if [ $? -ne 0 ]; then
    echo "Cluster creation failed. Please check the parameters in cluster-env."
    exit 1
else
    echo "Cluster definition created:  $CLUSTER_NAME.yaml"
    echo
fi

# Remove CNI addon from the generated YAML
yq eval '(select(.kind == "Cluster") | del(.spec.topology.variables[0].value.addons.cni)) // select(.kind != "Cluster")' $CLUSTER_NAME.yaml > $CLUSTER_NAME-with-flow-cni.yaml

# create Flow-CNI hcp

DOCKERBASE64=$(echo -n "docker.io:$DOCKER_FLOW_TOKEN" | base64 -w 0)
FLOWYAML="---
apiVersion: addons.cluster.x-k8s.io/v1alpha1
kind: HelmChartProxy
metadata:
  name: flow-cni
  namespace: ${WORKSPACE_NAMESPACE}
spec:
  clusterSelector:
    matchLabels:
      cluster.x-k8s.io/cluster-name: ${CLUSTER_NAME}
  repoURL: https://nutanix.github.io/helm-releases/
  chartName: nutanix-flow-cni
  version: 1.0.0
  namespace: flow-cni-system
  options:
    waitForJobs: true
    wait: true
    timeout: 30m
    install:
      createNamespace: true
  valuesTemplate: |
    nutanix-core-flow-ovn-kubernetes:
      k8sAPIServer: "https://${CONTROL_PLANE_ENDPOINT_IP}:6443" 
      podNetwork: "${POD_CIDR}" 
      serviceNetwork: "${SERVICE_CIDR}"
    global:
      dockerConfigSecret:
        registry: docker.io
        auth: ${DOCKERBASE64}
        create: true
      imagePullSecretName: "flow-cni-secret"
    imagePullSecrets:
      - name: flow-cni-secret
"

# Append the Flow-CNI HelmChartProxy definition to the cluster YAML
echo "$FLOWYAML" |yq e >> $CLUSTER_NAME-with-flow-cni.yaml

echo "to execute, run : kubectl apply -f $CLUSTER_NAME-with-flow-cni.yaml --server-side=true"
    