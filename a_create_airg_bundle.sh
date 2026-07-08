#!/bin/bash

#get bundle name
read -p "Enter desired bundle name to create (example: demo.tar): " BUNDLE

nkp create bundle --images-file images-file --oci-artifacts-file oci-artifacts-file --output-file $BUNDLE
