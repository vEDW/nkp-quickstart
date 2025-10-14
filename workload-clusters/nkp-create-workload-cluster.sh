#!/bin/bash

#check if cluster-env file exists
if [ ! -f ./cluster-env ]; then
    echo "cluster-env file not found. Please create it with the required variables by cloning cluster-env.example."
    exit 1
fi
source ./cluster-env

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
    ${SKIP_PREFLIGHT_CHECKS:+--skip-preflight-checks "$SKIP_PREFLIGHT_CHECKS"} \
    --dry-run -o yaml > $CLUSTER_NAME.yaml

#if NUTANIX_CCM_USER is set, edit CCM user.
if [ ! -z "$NUTANIX_CCM_USER" ]; then
    #get current user
    export CAPXSECRETNAME="$CLUSTER_NAME-pc-credentials"
    export CCMSECRETNAME="$CLUSTER_NAME-ccm-credentials"

    #backup cluster yaml
    cp $CLUSTER_NAME.yaml $CLUSTER_NAME-backup.yaml
    #extract current secret
    CAPX_K8S_SECRET=$(yq e '(select(.kind == "Secret" and .metadata.name == env(CAPXSECRETNAME)))|.' $CLUSTER_NAME.yaml)
    CURRENT_CAPX_USER_JSON=$(yq e '(select(.kind == "Secret" and .metadata.name == env(CAPXSECRETNAME)))|.data.credentials' $CLUSTER_NAME.yaml  |base64 -d )
    #check if error or empty
    if [ -z "$CURRENT_CAPX_USER_JSON" ]; then
        echo "Error: Could not find current CCM user in the generated yaml"
        exit 1
    fi
    #replace user in credentials
    UPDATED_CCM_USER_JSON=$(echo "$CURRENT_CAPX_USER_JSON" | jq --arg newuser "$NUTANIX_CCM_USER" '.[].data.prismCentral.username=$newuser')
    UPDATED_CCM_USER_JSON=$(echo "$UPDATED_CCM_USER_JSON" | jq --arg newpass "$NUTANIX_CCM_PASSWORD" '.[].data.prismCentral.password=$newpass')
    #encode to base64
    UPDATED_CCM_USER_JSON_BASE64=$(echo -n "$UPDATED_CCM_USER_JSON" | base64 -w 0 )
    CCM_K8S_SECRET=$(echo "$CAPX_K8S_SECRET" | yq e '.data.credentials="'$UPDATED_CCM_USER_JSON_BASE64'"')
    #change secret name for ccm
    CCM_K8S_SECRET=$(echo "$CCM_K8S_SECRET" | yq e '.metadata.name="'$CCMSECRETNAME'"')
    #insert updated secret back into cluster yaml but behind the namespace creation
    NAMESPACE_YAML=$(yq e '(select(.kind == "Namespace"))|.' $CLUSTER_NAME.yaml)
    OTHER_YAML=$(yq e 'select(.kind != "Namespace" and .metadata.name != env(CCMSECRETNAME))|.' $CLUSTER_NAME.yaml)    
    #edit OTHER_YAML to use new secret name for ccm

    OTHER_YAML=$(echo "$OTHER_YAML" | yq e '(select(.kind == "Cluster").spec.topology.variables[] | select(.name == "clusterConfig").value.addons.ccm.credentials.secretRef.name) = env(CCMSECRETNAME)')
    #recreate cluster yaml
    echo "$NAMESPACE_YAML" > $CLUSTER_NAME-ccm.yaml
    echo "---" >> $CLUSTER_NAME-ccm.yaml
    echo "$CCM_K8S_SECRET" >> $CLUSTER_NAME-ccm.yaml
    echo "---" >> $CLUSTER_NAME-ccm.yaml
#    echo "$CAPX_K8S_SECRET" >> $CLUSTER_NAME-ccm.yaml
#    echo "---" >> $CLUSTER_NAME-ccm.yaml
    echo "$OTHER_YAML" >> $CLUSTER_NAME-ccm.yaml
    mv $CLUSTER_NAME-ccm.yaml $CLUSTER_NAME.yaml

    echo "Updated CCM user in $CLUSTER_NAME.yaml" 

fi
#if NUTANIX_CSI_USER is set, edit CSI user.
if [ ! -z "$NUTANIX_CSI_USER" ]; then
    #get current user
    export CSISECRETNAME="$CLUSTER_NAME-pc-credentials-for-csi"

    #backup cluster yaml
    cp $CLUSTER_NAME.yaml $CLUSTER_NAME-csi-backup.yaml
    #extract current secret
    CSI_K8S_SECRET=$(yq e '(select(.kind == "Secret" and .metadata.name == env(CSISECRETNAME)))|.' $CLUSTER_NAME.yaml)
    CURRENT_CSI_USER_KEY=$(yq e '(select(.kind == "Secret" and .metadata.name == env(CSISECRETNAME)))|.data.key' $CLUSTER_NAME.yaml  |base64 -d )
    #check if error or empty
    if [ -z "$CURRENT_CSI_USER_JSON" ]; then
        echo "Error: Could not find current CSI user in the generated yaml"
        exit 1
    fi
    #replace user in credentials
    CURRENTPCENDPOINT=$(echo "$CURRENT_CSI_USER_KEY" | cut -d ":" -f1)
    CURRENTPCPORT=$(echo "$CURRENT_CSI_USER_KEY" | cut -d ":" -f2)

    UPDATED_CSI_USER_KEY="$CURRENTPCENDPOINT:$CURRENTPCPORT:$NUTANIX_CSI_USER:$NUTANIX_CSI_PASSWORD"
    #encode to base64
    export UPDATED_CCM_USER_KEY_BASE64=$(echo -n "$UPDATED_CSI_USER_KEY" | base64 -w 0 )

    # replace csi secret value in cluster yaml 

    UPDATEDYAML=$(yq -i '(select(.kind == "Secret" and .metadata.name == env(CSISECRETNAME)).data.key = env(UPDATED_CCM_USER_KEY_BASE64))' $CLUSTER_NAME.yaml)
    if [ $? -ne 0 ]; then
        echo "Error: Could not update CSI user in the generated yaml"
        exit 1
    fi    
    echo "Updated CSI user in the cluster yaml" 

fi


echo "Cluster yaml created. to deploy cluster run : kubectl apply -f $CLUSTER_NAME.yaml --server-side=true"
