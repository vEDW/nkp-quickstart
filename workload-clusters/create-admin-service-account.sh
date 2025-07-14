#!/bin/bash

# This script creates a cluster admin service account on a cluster and and creates a kubeconfig file for it.
# Select cluster to create service account on.

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

# Request name for the service account
echo
read -p "Enter name for the service account: " SERVICE_ACCOUNT_NAME
if [ -z "$SERVICE_ACCOUNT_NAME" ]; then
    echo "Service account name cannot be empty. Exiting."
    exit 1
fi
#crete the service account
kubectl create serviceaccount $SERVICE_ACCOUNT_NAME -n kube-system
if [ $? -ne 0 ]; then
    echo "Creating service account failed. Exiting."
    exit 1
fi
#create token secret for the service account
TOKENSECRET="apiVersion: v1
kind: Secret
metadata:
  name: $SERVICE_ACCOUNT_NAME-sa-token
  annotations:
    kubernetes.io/service-account.name: $SERVICE_ACCOUNT_NAME
  type: kubernetes.io/service-account-token
"

YAMLFILE=$SERVICE_ACCOUNT_NAME-sa-token.yaml
echo "$TOKENSECRET" > $YAMLFILE
kubectl apply -f $YAMLFILE -n kube-system
if [ $? -ne 0 ]; then
    echo "Creating token secret failed. Exiting."
    exit 1
fi

#check if service account token was created
TOKEN=$(kubectl get secret $SERVICE_ACCOUNT_NAME-sa-token -n kube-system -o jsonpath='{.data.token}' | base64 --decode)
if [ -z "$TOKEN" ]; then
    echo "Failed to retrieve token for service account: $SERVICE_ACCOUNT_NAME"
    exit 1
fi

# Create RBAC role binding for the service account
ADMINRBAC="apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $SERVICE_ACCOUNT_NAME-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: $SERVICE_ACCOUNT_NAME
  namespace: kube-system
"
RBACFILE=$SERVICE_ACCOUNT_NAME-cluster-admin.yaml
echo "$ADMINRBAC" > $RBACFILE
kubectl apply -f $RBACFILE -n kube-system
if [ $? -ne 0 ]; then
    echo "Creating RBAC role binding failed. Exiting."
    exit 1
fi
# Create kubeconfig file for the service account
KUBECONFIG_FILE="kubeconfig-${SERVICE_ACCOUNT_NAME}.yaml"
export USER_TOKEN_VALUE=$(kubectl -n kube-system get secret/kommander-cluster-admin-sa-token -o=go-template='{{.data.token}}' | base64 --decode)
export CURRENT_CONTEXT=$(kubectl config current-context)
export CURRENT_CLUSTER=$(kubectl config view --raw -o=go-template='{{range .contexts}}{{if eq .name "'''${CURRENT_CONTEXT}'''"}}{{ index .context "cluster" }}{{end}}{{end}}')
export CLUSTER_CA=$(kubectl config view --raw -o=go-template='{{range .clusters}}{{if eq .name "'''${CURRENT_CLUSTER}'''"}}"{{with index .cluster "certificate-authority-data" }}{{.}}{{end}}"{{ end }}{{ end }}')
export CLUSTER_SERVER=$(kubectl config view --raw -o=go-template='{{range .clusters}}{{if eq .name "'''${CURRENT_CLUSTER}'''"}}{{ .cluster.server }}{{end}}{{ end }}')
KUBECONFIG="apiVersion: v1
kind: Config
current-context: ${CURRENT_CONTEXT}
contexts:
- name: ${CURRENT_CONTEXT}
  context:
    cluster: ${CURRENT_CONTEXT}
    user: kommander-cluster-admin
    namespace: kube-system
clusters:
- name: ${CURRENT_CONTEXT}
  cluster:
    certificate-authority-data: ${CLUSTER_CA}
    server: ${CLUSTER_SERVER}
users:
- name: kommander-cluster-admin
  user:
    token: ${USER_TOKEN_VALUE}
"
echo "$KUBECONFIG" > $KUBECONFIG_FILE

#test if kubeconfig file works
if kubectl --kubeconfig=$KUBECONFIG_FILE get nodes; then
    echo "Kubeconfig file created successfully: $KUBECONFIG_FILE"
else
    echo "Failed to validate kubeconfig file. Exiting."
    exit 1
fi  
