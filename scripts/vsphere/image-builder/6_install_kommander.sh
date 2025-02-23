#!/bin/bash

#start timer
START=$( date +%s ) 

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
KUBECONFIG=$KUBECONFIGYAML nkp install kommander
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
