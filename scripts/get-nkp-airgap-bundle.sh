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

# Maintainer:   Jose Gomez (jose.gomez@nutanix.com)
# Contributors: 

#------------------------------------------------------------------------------

# To run:
# curl -sL https://raw.githubusercontent.com/nutanixdev/nkp-quickstart/main/scripts/get-nkp-cli | bash

#------------------------------------------------------------------------------

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

version=$(echo $url | cut -d "?" -f1 | rev | cut -d "/" -f1 | rev |cut -d "_" -f2)
cpwd=$(pwd)
bundle="$cpwd/nkp-$version"
echo $bundle > bundle-path

# Success message
echo "NKP airgap bundle extracted to : $bundle"