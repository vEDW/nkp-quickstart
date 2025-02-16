#!/bin/bash

#start timer
START=$( date +%s ) 

KUBECONFIGS=$(ls *.conf)
select KUBECONFIG in $KUBECONFIGS; do
    test=$(KUBECONFIG=$KUBECONFIG kubectl get nodes)
    if [ $? -ne 0 ]; then
        echo "KUBECONFIG $KUBECONFIG is not valid. Exiting."
        exit 1
    fi
    echo "you selected kubeconfig : ${KUBECONFIG}"
    echo
    break
done

echo "press enter to continue"
read
KUBECONFIG=$KUBECONFIG nkp install kommander

END=$( date +%s )
TIME=$( expr ${END} - ${START} )
TIME=$(date -d@$TIME -u +%Hh%Mm%Ss)
echo
echo "============================"
echo "===  Kommander installed ==="
echo "=== In ${TIME} ==="
echo "============================"
