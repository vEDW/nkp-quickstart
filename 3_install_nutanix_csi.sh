#!/bin/bash

bundlepath=$(cat bundle-path)
if [ $? -ne 0 ]; then
    echo "no bundle-path file present."
    exit 1
fi

# Check if directory is empty
if [ -z "$bundlepath" ]; then
    echo "No content in dir $bundlepath. Exiting."
    exit 1
fi

echo "using airgap bundle: $bundlepath"

source ./nkp-env

NKP_VERSION=$($bundlepath/cli/nkp version -o=json |jq -r '.nkp.gitVersion')
if [ $? -ne 0 ]; then
    echo "nkp cli not found in $bundlepath/cli/nkp"
    exit 1
fi


# Check csi charts is present. check directory for nutanix-csi-snapshot and nutanix-csi-storage directories
if [ ! -d "./nutanix-csi-snapshot" ]; then
    echo "nutanix-csi-snapshot directory not found. Please run 0_get_nutanix_csi_charts.sh to download the charts."
    exit 1
fi

if [ ! -d "./nutanix-csi-storage" ]; then
    echo "nutanix-csi-storage directory not found. Please run 0_get_nutanix_csi_charts.sh to download the charts."
    exit 1
fi

#select the kubeconfig file to use for helm install
echo "Select Management cluster kubeconfig file:"

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

#check config file is working by getting nodes
KUBECONFIG=${KUBECONFIGYAML} kubectl get nodes
if [ $? -ne 0 ]; then
    echo "KUBECONFIG ${KUBECONFIGYAML} is not valid. Exiting."
    exit 1
fi

#install the snapshot-controller helm chart
KUBECONFIG=${KUBECONFIGYAML} helm -n ntnx-system install snapshot-controller ./nutanix-csi-snapshot --create-namespace

echo "Checking installation of snapshot-controller helm chart"
echo

KUBECONFIG=${KUBECONFIGYAML} kubectl get pods -n ntnx-system -l app=csi-snapshot-controller
if [ $? -ne 0 ]; then
    echo "snapshot-controller pods not found. Exiting."
    exit 1
fi

KUBECONFIG=${KUBECONFIGYAML} kubectl get crd | grep snapshot
if [ $? -ne 0 ]; then
    echo "snapshot CRDs not found. Exiting."
    exit 1
fi

#install the CSI-driver helm chart
KUBECONFIG=${KUBECONFIGYAML} helm -n ntnx-system install nutanix-csi ./nutanix-csi-storage \
    --set kubernetesClusterDeploymentType=bare-metal \
    --set createSecret=false \
    --set prismCentralEndPoint="${NUTANIX_ENDPOINT}" \
    --set pcUsername="${NUTANIX_USERNAME}" \
    --set pcPassword="${NUTANIX_PASSWORD}"

#check installation of nutanix-csi helm chart
if [ $? -ne 0 ]; then
    echo "nutanix-csi helm chart installation failed. Exiting."
    exit 1
fi

#check CSI driver pods are running
echo "Checking installation of nutanix-csi helm chart"
KUBECONFIG=${KUBECONFIGYAML} kubectl get pods -n ntnx-system -l app=nutanix-csi-controller   


echo
echo "Create storage class yaml"
echo

# Create a Nutanix Volumes CSI Storage Class

cat <<EOF > nutanix-volume-storageclass.yaml
kubectl --kubeconfig ${CLUSTER_NAME}.conf create -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nutanix-volume
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
parameters:
  prismElementRef: <your_prism_element_uuid> # SSH into a Controller VM (CVM) on your target Prism Element cluster and run ncli cluster info to get the cluster UUID
  csi.storage.k8s.io/fstype: ext4
  storageContainer: <your_storage_container> # Change this to your target storage container
  storageType: NutanixVolumes
provisioner: csi.nutanix.com
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF

echo "Storage class yaml created. Please edit the prismElementRef and storageContainer values in nutanix-volume-storageclass.yaml before applying it to your cluster."


# Remove the local-volume-provisioner as the default storage class
kubectl --kubeconfig ${CLUSTER_NAME}.conf patch storageclass localvolumeprovisioner -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
