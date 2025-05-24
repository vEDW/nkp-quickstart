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

K9SRELEASE=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)
if [[ ${K9SRELEASE} == "null" ]]; then
    echo "github api rate limiting blocked request"
    echo "get latest version failed. Exiting."
    exit 1
fi

echo "Downloading k9s ${K9SRELEASE}"
url="https://github.com/derailed/k9s/releases/download/${K9SRELEASE}/k9s_Linux_amd64.tar.gz"

# Download the file with wget and check for errors
wget -O k9s_Linux_amd64.tar.gz "$url"
if [ $? -ne 0 ]; then
    echo "Download failed. Exiting."
    exit 1
fi

# Extract the downloaded file and check for errors
tar xzf k9s_Linux_amd64.tar.gz 
if [ $? -ne 0 ]; then
    echo "Extraction failed. Exiting."
    exit 1
fi

# Make the file executable and move it to /usr/local/bin
chmod +x ./k9s
if [ $? -eq 0 ]; then
    sudo mv ./k9s /usr/local/bin
else
    echo "Failed to make k9s executable. Exiting."
    exit 1
fi

# Clean up downloaded files
rm -f k9s_Linux_amd64.tar.gz LICENSE README.md

# Success message
echo "k9s CLI installed successfully!"
echo "checking version"
k9s version
