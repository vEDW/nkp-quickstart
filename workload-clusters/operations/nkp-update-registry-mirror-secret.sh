#!/usr/bin/env bash

#------------------------------------------------------------------------------

# Copyright 2024 Nutanix, Inc
#
# Licensed under the MIT License;
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”),
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#------------------------------------------------------------------------------

# This script updates the registry mirror secret in a NKP workload cluster by creating a new secret with the updated credentials
# and patching the workload cluster to use the new secret.
# This will trigger a rolling update of the nodes in the workload cluster to pick up the new registry mirror credentials.

#Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl command not found. Please install kubectl first."
    exit 1
fi

#Check if yq cli is installed
if ! command -v yq &> /dev/null; then
    echo "yq command not found. Please install yq first."
    exit 1
fi

#select NKP Management Cluster kubeconfig context
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

#check if this is a NKP Management cluster
KOMANDERCRD=$(kubectl  api-resources |grep cluster.x-k8s.io)
if [[ -z "$KOMANDERCRD" ]]; then
    echo "This is not a NKP Management Cluster. Please select a valid management cluster."
    exit 1
fi

#select workload cluster

CLUSTERS=$(kubectl get cluster --no-headers -A |awk '{print $2}')
echo
echo "Select workload cluster to get kubeconfig or CTRL-C to quit"
select CLUSTER in $CLUSTERS; do 
    CLUSTERNS=$(kubectl get cluster --no-headers -A |grep ${CLUSTER} | awk '{print $1}')
    echo "you selected cluster  : ${CLUSTER} in namespace : ${CLUSTERNS}"
    echo 
    break
done

#Check if registry mirror secret variables are set
SECRETREF=$(kubectl get cluster $CLUSTER -n $CLUSTERNS  -o jsonpath='{.spec.topology.variables[].value.globalImageRegistryMirror.credentials.secretRef.name}')
if [[ -z "$SECRETREF" ]]; then
    echo "No registry mirror secret found for cluster $CLUSTER. Exiting."
    exit 1
fi
echo "Registry Mirror SecretRef : $SECRETREF"

#Get existing secret data
EXISTINGSECRETYAML=$(kubectl get secret $SECRETREF -n $CLUSTERNS -o yaml)
if [[ -z "$EXISTINGSECRETYAML" ]]; then
    echo "Failed to retrieve existing secret $SECRETREF in namespace $CLUSTERNS. Exiting."
    exit 1
fi
# echo "$EXISTINGSECRETYAML" | yq e

#Prompt for new registry mirror credentials
echo 
read -sp "Enter new registry mirror password: " NEWPASSWORD
echo
#check if password is empty
if [[ -z "$NEWPASSWORD" ]]; then
    echo "Password cannot be empty. Exiting."
    exit 1
fi

#Base64 encode the new password
NEWPASSWORDB64=$(echo -n "$NEWPASSWORD" | base64)   

#Create new secret YAML with updated password
NEWSECRETNAME="${SECRETREF}-updated-$(date +%Y-%m-%d-%Hh%M)"
NEWSECRETYAML=$(echo "$EXISTINGSECRETYAML" | yq e ".data.password = \"${NEWPASSWORDB64}\" | .metadata.name = \"${NEWSECRETNAME}\" | del(.metadata.resourceVersion) | del(.metadata.uid) | del(.metadata.creationTimestamp)" -)
echo "$NEWSECRETYAML" | yq e
echo

# ready to apply ?
read -p "Apply new secret ${NEWSECRETNAME} to namespace ${CLUSTERNS} and patch cluster ${CLUSTER} to use it? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    echo "Aborting."
    exit 0
fi

#Apply new secret
NEWSECRETYAMLFILE=$(mktemp /tmp/new-secret-XXXX.yaml)
echo "$NEWSECRETYAML" > $NEWSECRETYAMLFILE

kubectl apply -n $CLUSTERNS -f $NEWSECRETYAMLFILE
if [[ $? -ne 0 ]]; then
    echo "Failed to create new secret $NEWSECRETNAME in namespace $CLUSTERNS.   Exiting."
    exit 1
fi
#delete temp file
rm -f $NEWSECRETYAMLFILE
echo "Created new secret $NEWSECRETNAME in namespace $CLUSTERNS."

#Patch workload cluster to use new secret
kubectl patch cluster $CLUSTER -n $CLUSTERNS --type='json' -p="[{'op':'replace','path':'/spec/topology/variables/0/value/globalImageRegistryMirror/credentials/secretRef/name','value':'${NEWSECRETNAME}'}]"
if [[ $? -ne 0 ]]; then
    echo "Failed to patch cluster $CLUSTER to use new secret $NEWSECRETNAME. Exiting."
    exit 1
fi
echo "Patched cluster $CLUSTER to use new secret $NEWSECRETNAME."
echo "This will trigger a rolling update of the nodes in the workload cluster to pick up the new registry mirror credentials."
echo "Done."

# watch rollout status
echo
kubectl get machine -n $CLUSTERNS -l "cluster.x-k8s.io/cluster-name"==$CLUSTER -w