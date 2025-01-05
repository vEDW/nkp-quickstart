source ./cluster-env

NODEPOOL_NAME=dh1
NUTANIX_PRISM_ELEMENT_CLUSTER_NAME=dh1
NUTANIX_SUBNET_NAME=User.dh1
NAMESPACE=$(kubectl get clusters -o json -A |jq -r --arg CLUSTER $CLUSTER_NAME '.items[].metadata|select(.name==$CLUSTER)|.namespace') 

nkp create nodepool nutanix $NODEPOOL_NAME -c $CLUSTER_NAME -n $NAMESPACE \
    --prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --subnets $NUTANIX_SUBNET_NAME \
    --replicas 1 \
    --vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --dry-run -o yaml > $CLUSTER_NAME-$NODEPOOL_NAME.yaml

