#!/bin/bash

#start timer
START=$( date +%s ) 

#check if bundle-path is present
bundlepath=$(cat bundle-path)
if [ $? -ne 0 ]; then
    echo "no bundle-path file present. please run 0_get_airgap_bundle.sh first"
    exit 1
fi

# Check if directory is empty
if [ -z "$bundlepath" ]; then
    echo "No content in dir $bundlepath. Exiting."
    exit 1
fi
echo
echo "using airgap bundle : $bundlepath"
echo


KUBECONFIGS=$(ls *.conf)
select KUBECONFIGYAML in $KUBECONFIGS; do
    test=$(KUBECONFIG=$KUBECONFIGYAML kubectl get nodes)
    if [ $? -ne 0 ]; then
        echo "KUBECONFIG $KUBECONFIGYAML is not valid. Exiting."
        exit 1
    fi
    echo "you selected kubeconfig : ${KUBECONFIGYAML}"
    echo
    break
done

echo "press enter to continue"
read
KUBECONFIG=$KUBECONFIGYAML $bundlepath/cli/nkp install kommander
if [ $? -ne 0 ]; then
    echo "problem installing kommander using $KUBECONFIGYAML . Exiting."
    exit 1
fi
echo
echo "To get dashboard login info run the following command : "
echo "nkp get dashboard --kubeconfig=$KUBECONFIGYAML"
echo

END=$( date +%s )
TIME=$( expr ${END} - ${START} )
TIME=$(date -d@$TIME -u +%Hh%Mm%Ss)
echo
echo "============================"
echo "===  Kommander installed ==="
echo "=== In ${TIME} ==="
echo "============================"
