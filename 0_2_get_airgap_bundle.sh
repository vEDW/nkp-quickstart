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

# Maintainer:   Eric De Witte (eric.dewitte@nutanix.com)
# Contributors: 

#------------------------------------------------------------------------------

#check if wget is installed
if ! command -v wget &> /dev/null; then
    echo "wget could not be found, please install it first."
    exit 1
fi

#verify if enough free space is available
free_space=$(df -h . | awk 'NR==2 {print $4}')
if [[ $free_space == *G ]]; then
    free_space_value=$(echo $free_space | sed 's/G//')
    if (( $(echo "$free_space_value < 30" | bc -l) )); then
        echo "Not enough free space available. At least 30GB is required."
        exit 1
    fi
elif [[ $free_space == *M ]]; then
    free_space_value=$(echo $free_space | sed 's/M//')
    if (( $free_space_value < 30.720 )); then
        echo "Not enough free space available. At least 30GB is required."
        exit 1
    fi
else
    echo "Unable to determine free space. Exiting."
    exit 1
fi
# Prompt the user for the download link
echo 'open browser to site : https://portal.nutanix.com/page/downloads?product=nkp and find "NKP Airgapped Bundle" '
read -p "Enter 'NKP airgap bundle' download link: " url < /dev/tty

# Check if URL is empty
if [ -z "$url" ]; then
    echo "No URL provided. Exiting."
    exit 1
fi

# Download the file with wget and check for errors
wget -O nkp-airgap.tar.gz "$url"
if [ $? -ne 0 ]; then
    echo "Download failed. Exiting."
    exit 1
fi

# Extract the downloaded file and check for errors
echo
echo "Extracting bundle - this can take some time"

tar xzf nkp-airgap.tar.gz
if [ $? -ne 0 ]; then
    echo "Extraction failed. Exiting."
    exit 1
fi
rm -f nkp-airgap.tar.gz

version=$(echo $url | cut -d "?" -f1 | rev | cut -d "/" -f1 | rev |cut -d "_" -f2)
cpwd=$(pwd)
bundle="$cpwd/nkp-$version"
echo $bundle > bundle-path

# Success message
echo "NKP airgap bundle extracted to : $bundle"
