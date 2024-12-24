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

RELEASE=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | jq -r .tag_name)
if [[ ${RELEASE} == "null" ]]; then
    echo "github api rate limiting blocked request"
    echo "get latest version failed. Exiting."
    exit 1
fi

echo "Downloading kubectx ${RELEASE}"
url="https://github.com/ahmetb/kubectx/releases/download/${RELEASE}/kubectx_${RELEASE}_linux_x86_64.tar.gz"
# Download the file with wget and check for errors
wget -O kubectx_linux_x86_64.tar.gz "$url"
if [ $? -ne 0 ]; then
    echo "Download failed. Exiting."
    exit 1
fi

# Extract the downloaded file and check for errors
tar xzf kubectx_linux_x86_64.tar.gz
if [ $? -ne 0 ]; then
    echo "Extraction failed. Exiting."
    exit 1
fi

echo "Downloading kubens ${RELEASE}"
url="https://github.com/ahmetb/kubectx/releases/download/${RELEASE}/kubens_${RELEASE}_linux_x86_64.tar.gz"
# Download the file with wget and check for errors
wget -O kubens_linux_x86_64.tar.gz "$url"
if [ $? -ne 0 ]; then
    echo "Download failed. Exiting."
    exit 1
fi

# Extract the downloaded file and check for errors
tar xzf kubens_linux_x86_64.tar.gz
if [ $? -ne 0 ]; then
    echo "Extraction failed. Exiting."
    exit 1
fi

# Make the file executable and move it to /usr/local/bin
sudo mv ./kubectx /usr/local/bin
sudo mv ./kubens /usr/local/bin

# Clean up downloaded files
rm -f kubectx_linux_x86_64.tar.gz kubens_linux_x86_64.tar.gz LICENSE

# Success message
echo "kubectx and kubens CLI installed successfully!"
echo "checking kubectx version"
kubectx -V
echo "checking kubens version"
kubens -V