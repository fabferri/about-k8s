#!/bin/bash
#
# to log in with the device authentication code in the browser, you need to use the parameter –use-device-code:
# az login --use-device-code
#
# parameters:
#    $vmSize: Size of Virtual Machines to create as Kubernetes nodes.
#             "Standard_B2ms" -> vCore:2,	RAM:8 GiB,	Temporary storage:16 GiB
subscriptionName='AzureDemo'
location='uksouth'
vmSize='Standard_B2ms'
rg='k8s-5'
clusterName='aks5'
####
####
GREEN='\033[0;32m'
CYAN='\033[36m'
YELLOW='\033[33m'
NOCOLOR='\033[0m'

echo -e "${GREEN} $(date) - Select the azure subscription"
az account set --subscription $subscriptionName

echo -e "${GREEN} $(date) - default Azure subscription: "
# az account list --query "[?isDefault]" 
# az account list --output table --query '[?isDefault].{ name: name, isDefault: isDefault'}
az account list --output tsv --query '[?isDefault].{ name: name'}

echo -e "${GREEN} $(date) - create the resource group: $rg" 
az group create --name $rg --location $location

echo -e "${CYAN} $(date) - getting the public key from ~/.ssh/id_rsa.pub" 
SSH=$(cat ~/.ssh/id_rsa.pub)

echo -e "${GREEN} $(date) - create the AKS cluster: $clusterName" 
if [[ -n "$SSH" ]]
then
    echo -e "${YELLOW} $(date) - SSH public key exists: $SSH"
    echo -e "${NOCOLOR}" 
    # -ssh-key-value: public key path or key contents to install on node VMs for SSH access.
    az aks create -g $rg -n $clusterName --enable-managed-identity --node-count 1 --ssh-key-value "$SSH" --os-sku Ubuntu --node-vm-size $vmSize
else 
    echo -e "${YELLOW} $(date) - generate a new SSH public key"
    echo -e "${NOCOLOR}" 
    # Generate SSH public and private key files if missing. The keys will be stored in the ~/.ssh directory
    az aks create -g $rg -n $clusterName --enable-managed-identity --node-count 1 --generate-ssh-keys --os-sku Ubuntu --node-vm-size $vmSize
fi

# collect credentials from the Kubernetes configuration file (default location: ~/.kube/config), and configures the Kubernetes CLI to use them. 
# --overwrite-existing: overwrite any existing credentials with the same entry in the Kubernetes configuration file
echo -e "${GREEN} $(date) - get the credential to access to the cluster: $clusterName"
az aks get-credentials --resource-group $rg --name $clusterName --overwrite-existing

## Enable CSI storage drivers on an existing cluster
echo -e "${GREEN} $(date) - update the cluster: $clusterName adding the CSI storage driver"
echo -e "${NOCOLOR}" 
az aks update -g $rg -n $clusterName --enable-file-driver 

# Verify the connection to your cluster
kubectl get nodes -o wide
