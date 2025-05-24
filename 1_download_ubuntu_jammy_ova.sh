#!/bin/bash

#download Ubuntu 22.04 Jammy Jellyfish OVA

url="https://cloud-images.ubuntu.com/jammy/current/"
MD5url="https://cloud-images.ubuntu.com/jammy/current/MD5SUMS"

# Use wget to list the contents of the directory
output=$(wget -q -O - "$url")

# Filter the output to get the image filenames
images=$(echo "$output" | grep -oE 'jammy-server-cloudimg-[a-z0-9-]+(\.ova)')

sortedimages=$(echo "$images" | sort | uniq)
# Print the list of images
if [ -n "$sortedimages" ]; then
        CONTEXTS=$(kubectl config get-contexts --output=name)
        echo
        echo "Select Ubuntu OVA or CTRL-C to quit"
        select image in $sortedimages; do 
            echo "you selected image : ${image}"
            echo 
            break
        done
    else
        echo "No images found."
fi

imagemd5=$(curl -s $MD5url |grep $image |awk '{print $1}')
echo "image : $image"
echo "md5 : $imagemd5"

# Download the image
echo "Downloading $image"
wget -q --show-progress "$url$image"
#check MD5
md5=$(md5sum $image |awk '{print $1}')
if [ "$md5" == "$imagemd5" ]; then
    echo "MD5 check passed"
else
    echo "MD5 check failed"
    exit 1
fi


