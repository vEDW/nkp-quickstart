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

#check if cluster-env is present
if [ ! -f ./cluster-env ]; then
    echo "cluster-env file not found! Please create one first by copying cluster-env.example and editing the values as needed."
    exit 1
fi 

# check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "yq could not be found, please install yq to proceed. (../tools/yq_cli.sh)"
    exit 1
fi

#load cluster-env
source ./cluster-env

# check if $CLUSTER_NAME.yaml is present.
if [ ! -f ./$CLUSTER_NAME.yaml ]; then
    echo "$CLUSTER_NAME.yaml file not found! Please run nkp-create-workload-cluster.sh first to create the cluster definition file."
    exit 1
fi
# check if $CLUSTER_NAME-cilium-cni-helm-values-cm.yaml is present.
if [ ! -f ./$CLUSTER_NAME-cilium-cni-helm-values-cm.yaml ]; then
    echo "$CLUSTER_NAME-cilium-cni-helm-values-cm.yaml file not found! Please run 1_create_cilium_configmap.sh first to create the cilium configmap file."
    exit 1
fi

# merge the two yamls into one file
cat  $CLUSTER_NAME-cilium-cni-helm-values-cm.yaml $CLUSTER_NAME.yaml | yq e > $CLUSTER_NAME-with-cilium.yaml
if [ $? -ne 0 ]; then
    echo "Failed to merge YAML files. Exiting."
    exit 1
fi  

#editing cni add-ons to reference configmap
CONFIGMAP_NAME=$( yq e 'select(.kind == "ConfigMap")|.metadata.name' $CLUSTER_NAME-cilium-cni-helm-values-cm.yaml  )
if [ -z "$CONFIGMAP_NAME" ]; then
    echo "Failed to extract ConfigMap name. Exiting."
    exit 1
fi

yq -i '(select(.kind == "Cluster").spec.topology.variables[] | select(.name == "clusterConfig").value.addons.cni) += {"values": { "sourceRef": {"name": env(CONFIGMAP_NAME), "kind": "ConfigMap" } } }'  $CLUSTER_NAME-with-cilium.yaml
if [ $? -ne 0 ]; then
    echo "Failed to update CNI addon in the merged YAML file. Exiting."
    exit 1
fi
echo "Merged YAML file with Cilium ConfigMap created successfully: $CLUSTER_NAME-with-cilium.yaml"
echo
echo "to deploy, run : kubectl apply -f $CLUSTER_NAME-with-cilium.yaml --server-side=true"
