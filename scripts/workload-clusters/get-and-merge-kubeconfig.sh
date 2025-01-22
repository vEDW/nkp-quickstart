#!/bin/bash

if [ "$1" == "" ] ; then

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
    echo "Select workload cluster to get kubeconfig or CTRL-C to quit"
    select CLUSTER in $CLUSTERS; do 
        CLUSTERNS=$(kubectl get cluster --no-headers -A |grep ${CLUSTER} | awk '{print $1}')
        echo "you selected cluster  : ${CLUSTER} in namespace : ${CLUSTERNS}"
        echo 
        break
    done

    CLUSTERKUBEYAML=$(nkp get kubeconfig -c ${CLUSTER} -n ${CLUSTERNS})
    if [ $? -ne 0 ]; then
        echo "get kubeconfig failed. Exiting."
        exit 1
    fi

else
    CLUSTERKUBEYAML=$(cat $1)
fi


#clusters
CLUSTER=$(echo "$CLUSTERKUBEYAML" |yq e '.clusters[]')
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
USERS=$(echo "$CLUSTERKUBEYAML" |yq e '.users[]')
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
CONTEXTS=$(echo "$CLUSTERKUBEYAML" |yq e '.contexts[]')
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

