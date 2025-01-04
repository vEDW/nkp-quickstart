source ./nkp-env

NKP_VERSION=$(nkp version -o=json |jq -r '.nkp.gitVersion')

nkp create cluster nutanix -c $CLUSTER_NAME \
    --kind-cluster-image $REGISTRY_MIRROR_URL/mesosphere/konvoy-bootstrap:$NKP_VERSION \
    --endpoint https://$NUTANIX_ENDPOINT:$NUTANIX_PORT \
    --insecure \
    --kubernetes-service-load-balancer-ip-range $LB_IP_RANGE \
    --control-plane-endpoint-ip $CONTROL_PLANE_ENDPOINT_IP \
    --control-plane-vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --control-plane-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --control-plane-subnets $NUTANIX_SUBNET_NAME \
    --control-plane-replicas 3 \
    --worker-vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --worker-prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --worker-subnets $NUTANIX_SUBNET_NAME \
    --worker-replicas 4 \
    --csi-storage-container $NUTANIX_STORAGE_CONTAINER_NAME \
    --csi-hypervisor-attached-volumes=false \
    --registry-mirror-url https://$REGISTRY_MIRROR_URL \
    --registry-mirror-password=$REGISTRY_MIRROR_USERNAME \
    --registry-mirror-username="$REGISTRY_MIRROR_PASSWORD" \
    --self-managed