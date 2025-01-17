source ./cluster-env

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

CLUSTERS=$(kubectl get cluster --no-headers -A |awk '{print $2}')
echo
echo "Select workload cluster to create node pool or CTRL-C to quit"
select CLUSTER in $CLUSTERS; do 
    CLUSTERNS=$(kubectl get cluster --no-headers -A |grep ${CLUSTER} | awk '{print $1}')
    echo "you selected cluster  : ${CLUSTER} in namespace : ${CLUSTERNS}"
    echo 
    break
done

#NODEPOOL_NAME=dh1
echo
read -p "Enter new nodepool name: " NODEPOOL_NAME < /dev/tty

#NUTANIX_PRISM_ELEMENT_CLUSTER_NAME=dh1
echo
read -p "Enter new nodepool name: " NUTANIX_PRISM_ELEMENT_CLUSTER_NAME < /dev/tty

#NUTANIX_SUBNET_NAME=User.dh1
echo
read -p "Enter new nodepool name: " NUTANIX_SUBNET_NAME < /dev/tty


nkp create nodepool nutanix $NODEPOOL_NAME -c $CLUSTER -n $CLUSTERNS \
    --prism-element-cluster $NUTANIX_PRISM_ELEMENT_CLUSTER_NAME \
    --subnets $NUTANIX_SUBNET_NAME \
    --replicas 1 \
    --vm-image $NUTANIX_MACHINE_TEMPLATE_IMAGE_NAME \
    --dry-run -o yaml > $CLUSTER_NAME-$NODEPOOL_NAME.yaml

echo "nodepool definition created:  $CLUSTER_NAME-$NODEPOOL_NAME.yaml"
echo
echo "to execute, run : kubectl apply -f $CLUSTER_NAME-$NODEPOOL_NAME.yaml"