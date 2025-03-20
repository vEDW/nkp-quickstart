# Nutanix Kubernetes Platform - Quickstart Guide

## TL;DR

Steps to install all the required CLIs (nkp, kubectl and helm) to create and manage NKP clusters.

1. Add NKP Rocky Linux image from the Nutanix Support Portal to Prism Central

1. Create a jump host with 2 vCPUs, 4 GB memory, use the Rocky image (update disk to 128 GiB), and the following Cloud-init custom script : [cloud-init](./scripts/cloud-init)

1. SSH to `nutanix@<jump host_IP>` (default password: nutanix/4u - unless you modified it in the cloud-init file)

1. Install the NKP CLI with the command: [get-nkp-cli](./scripts/get-nkp-cli)

    When prompted, you must use the download link as-is, which is available in the Nutanix portal.

## Table of Contents

1. [Overview](#overview)

1. [Prerequisites Checklist](#prerequisites-checklist)

1. [Deploy Linux jump host](#deploy-linux-jump-host)

1. [Install NKP CLI](#install-nkp-cli)

1. [(Optional) Create NKP Cluster on Nutanix](#optional-create-nkp-cluster-on-nutanix)

## Overview

The NKP CLI is a command-line interface for managing NKP-based workflows. This guide provides a quick and easy way to install the required CLIs (nkp, kubectl and helm) using the Rocky Linux image provided by Nutanix in the [Nutanix Support Portal](https://portal.nutanix.com/page/downloads?product=nkp).

## Prerequisites Checklist

For NKP CLI:

- Internet connectivity
- Add NKP Rocky Linux to Prism Central. **DO NOT CHANGE** the auto-populated image name

    <details>
    <summary>click to view example</summary>
    <IMG src="./images/add_nkp_rocky_os_image.png" atl="Add NKP Rocky OS image" />
    </details>

(Optional) For NKP cluster creation:

- Static IP address for the control plane VIP
- One or more IP addresses for the NKP dashboard and load balancing service

## Deploy Linux jump host

1. Connect to Prism Central

1. Create a virtual machine

    - Name: nkp-jump host
    - vCPUs: 2
    - Memory: 16
    - Disk: Clone from Image (select the Rocky Linux you previously uploaded)
    - Disk Capacity: 128 (default is 20)
    - Guest Customization: Cloud-init (Linux)
    - Custom Script: [cloud-init](./scripts/cloud-init)

1. Power on the virtual machine

## Install NKP CLI

1. Connect to your jump host using SSH (default password: nutanix/4u)

    ```shell
    ssh nutanix@<jump host_IP>
    ```

1. git clone this repo

    ```shell
    git clone https://github.com/vEDW/nkp-quickstart.git
    ```

1. Install the NKP CLI with the command: [get-nkp-cli](./scripts/get-nkp-cli)

    ```shell
    cd nkp-quickstart/scripts
    ./get-nkp-cli
    ```

    When prompted, you must use the download link as-is, which is available in the Nutanix portal.

## (Optional) Create NKP cluster on Nutanix

1. Before you start, ensure you meet the prerequisites:

    - Static IP address for the control plane VIP
    - One or more IP addresses for the NKP dashboard and load-balancing service

    Note: The IP addresses must be in the same subnet as the virtual machines.

1. Choose one of the following two installation methods:

    - **Prompt-based installation**. Use this method when the Internet connection for the NKP cluster isn’t shared with more users.
    - **CLI installation**. Use this method when the Internet connection for the NKP cluster is shared between many users.

### Prompt-based installation

This installation method gives less control on the cluster configuration. For example, the NKP cluster will be created with three control plane nodes and four worker nodes.

We recommend starting a tmux session in case your ssh connection is at risk of disconnection (like laptop going into sleep mode) as the process can take some time based on several paramters (like download speed).

```shell
nkp create cluster nutanix
```

### CLI installation

This installation method lets you fully customize your cluster configuration. The following commands create a cluster with one control plane node and three worker nodes.

1. Before running the following command in your jump host VM, update the values with your environment: [nkp-env](./scripts/nkp-env)

1. The next command will start the installation process of an NKP management cluster: [nkp-create-cluster](./scripts/nkp-create-mgmt-cluster.sh)

## Support and Disclaimer

These code samples are intended as standalone examples. Please be aware that all public code samples provided by Nutanix are unofficial in nature, are provided as examples only, are unsupported, and will need to be heavily scrutinized and potentially modified before they can be used in a production environment. All such code samples are provided on an as-is basis, and Nutanix expressly disclaims all warranties, express or implied. All code samples are © Nutanix, Inc., and are provided as-is under the MIT license (<https://opensource.org/licenses/MIT>).
