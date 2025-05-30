#!/bin/bash

[ "$1" == "" ] && echo "usage: $0 <kubeconfig file to merge to .kube/config>" && exit 1 
CLUSTERKUBEYAML="$1"

#clusters
CLUSTER=$(yq e '.clusters[]' $CLUSTERKUBEYAML )
if [ $? -ne 0 ]; then
    echo "getting clusters failed failed. Exiting."
    exit 1
fi
CLUSTERNAME=$(echo "$CLUSTER" | yq e '.name')
if [ $? -ne 0 ]; then
    echo "getting cluster name failed. Exiting."
    exit 1
fi

#users
USERS=$(yq e '.users[]' $CLUSTERKUBEYAML  )
if [ $? -ne 0 ]; then
    echo "getting users failed. Exiting."
    exit 1
fi
USERNAME=$(echo "$USERS" | yq e '.name')
if [ $? -ne 0 ]; then
    echo "getting user name failed. Exiting."
    exit 1
fi

#contexts
CONTEXTS=$(yq e '.contexts[]' $CLUSTERKUBEYAML  )
if [ $? -ne 0 ]; then
    echo "getting contexts failed. Exiting."
    exit 1
fi
CONTEXTNAME=$(echo "$CONTEXTS" | yq e '.name')
if [ $? -ne 0 ]; then
    echo "getting context name failed. Exiting."
    exit 1
fi

#kubeconfig file
KUBECONF=$(yq e ~/.kube/config)
if [ $? -ne 0 ]; then
    echo "reading kubeconfig file failed. Exiting."
    exit 1
fi

#delete cluster if present
KUBECONF=$(echo "$KUBECONF" |test="$CLUSTERNAME" yq e 'del(.clusters[]|select (.name == env(test)))')
#Add cluster
KUBECONF=$(echo "$KUBECONF" |test="$CLUSTER" yq '.clusters +=[env(test)]')

#delete user if present
KUBECONF=$(echo "$KUBECONF" |test="$USERNAME" yq e 'del(.users[]|select (.name == env(test)))')
#Add user
KUBECONF=$(echo "$KUBECONF" |test="$USERS" yq '.users +=[env(test)]')

#delete context if present
KUBECONF=$(echo "$KUBECONF" |test="$CONTEXTNAME" yq e 'del(.contexts[]|select (.name == env(test)))')
#Add context
KUBECONF=$(echo "$KUBECONF" |test="$CONTEXTS" yq '.contexts +=[env(test)]')

echo "$KUBECONF" | yq e
if [ $? -ne 0 ]; then
    echo "generating kubeconfig file failed. Exiting."
    exit 1
fi

echo "$KUBECONF" | yq e > ~/.kube/config

