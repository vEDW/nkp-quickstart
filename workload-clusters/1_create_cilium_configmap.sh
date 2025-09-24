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

# check if values.yaml is present
if [ ! -f ./values.yaml ]; then
    echo "values.yaml file not found! Please run 0_get-cilium-default-values.sh first to download the default values file."
    exit 1
fi  

#load cluster-env
source ./cluster-env

kubectl create cm $CLUSTER_NAME-cilium-cni-helm-values-cm --from-file=values.yaml --dry-run=client -o yaml > $CLUSTER_NAME-cilium-cni-helm-values-cm.yaml
if [ $? -ne 0 ]; then
    echo "Failed to create ConfigMap. Exiting."
    exit 1
fi
echo "---" >> $CLUSTER_NAME-cilium-cni-helm-values-cm.yaml
echo "ConfigMap $CLUSTER_NAME-cilium-cni-helm-values-cm created successfully and saved to $CLUSTER_NAME-cilium-cni-helm-values-cm.yaml"
echo
