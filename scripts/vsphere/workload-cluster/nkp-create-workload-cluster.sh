source ./cluster-env

nkp create cluster vsphere \
  --cluster-name ${CLUSTER_NAME} \
  --network ${NETWORK_NAME} \
  --control-plane-endpoint-host ${CONTROL_PLANE_ENDPOINT_IP} \
  --data-center ${DATACENTER_NAME} \
  --data-store ${DATASTORE_NAME} \
  --folder ${FOLDER_NAME} \
  --server ${VCENTER_API_SERVER_URL} \
  --ssh-public-key-file ${SSH_PUBLIC_KEY_FILE} \
  --resource-pool ${RESOURE_POOL_NAME} \
  --virtual-ip-interface ${ip_interface_name} \
  --vm-template ${TEMPLATE_NAME} \
  --dry-run \
  --output=yaml \
  > ${CLUSTER_NAME}.yaml
