#!/bin/bash

#check if nkp cli is installed
if ! command -v nkp &> /dev/null
then
    echo "nkp not found - please install nkp cli - see nkp-quickstart/scripts/get-nkp-cli"
    exit
fi

#provide useage info
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "Usage: $0 [kubeconfig_file]"
    echo "If kubeconfig_file is not provided, the script will prompt you to select a context from your existing kubeconfig."
    echo "If kubeconfig_file is provided, it will be used directly."
    exit 0
fi

if [ "$1" == "" ] ; then

    CONTEXTS=$(kubectl config get-contexts --output=name)
    #check if at least one context is available
    if [ -z "$CONTEXTS" ]; then
        echo "No kubernetes contexts found. Exiting."
        exit 1
    fi

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

