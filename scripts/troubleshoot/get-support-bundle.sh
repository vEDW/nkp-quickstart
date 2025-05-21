#!/bin/bash

#check if nkp cli is installed
if ! command -v nkp &> /dev/null
then
    echo "nkp not found - please install nkp cli - see nkp-quickstart/scripts/get-nkp-cli"
    exit
fi

#ask to select existing kubeconfig context or kubeconfig file

if [ "$1" == "" ] ; then

    CONTEXTS=$(kubectl config get-contexts --output=name)
    echo
    echo "Select kubernetes cluster or CTRL-C to quit"
    select CONTEXT in $CONTEXTS; do 
        echo "you selected cluster context : ${CONTEXT}"
        echo 
        CLUSTERCTX="${CONTEXT}"
        break
    done

    kubectl config use-context $CLUSTERCTX


    #Get support bundle
    nkp diagnose
    #check if nkp diagnose was successful
    if [ $? -ne 0 ]; then
        echo "nkp diagnose failed. Exiting."
        exit 1
    fi
    echo "nkp diagnose completed successfully"
else
    echo "using kubeconfig file $1"
    #check if file exists
    if [ ! -f "$1" ]; then
        echo "Kubeconfig file not found: $1"
        exit 1
    fi
    KUBECONFIG=$1 nkp diagnose
    #check if nkp diagnose was successful
    if [ $? -ne 0 ]; then
        echo "nkp diagnose failed. Exiting."
        exit 1
    fi
    echo "nkp diagnose completed successfully"
fi

