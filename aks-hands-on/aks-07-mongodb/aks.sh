#!/bin/bash
#
# to log in with the device authentication code in the browser, you need to use the parameter –use-device-code:
# az login --use-device-code
#
# parameters:
#    $vmSize: Size of Virtual Machines to create as Kubernetes nodes.
#             "Standard_B2ms" -> vCore:2,	RAM:8 GiB,	Temporary storage:16 GiB
echo 'Select the azure subscription'
az account set --subscription "AzureDemo"
location="uksouth"
vmSize="Standard_B2ms"
rg='k8s-2'
clusterName='aks2'
####
####
echo 'default Azure subscription: '
az account list --query "[?isDefault]" 

echo "$(date) - create the resource group: $rg" 
az group create --name $rg --location $location

echo "$(date) - getting the public key from ~/.ssh/id_rsa.pub" 
SSH=$(cat ~/.ssh/id_rsa.pub)

echo "$(date) - create the AKS cluster: $clusterName" 
if [ -n "$SSH" ]; then
    echo "$(date) - SSH public key exists: $SSH"
    az aks create -g $rg -n $clusterName --enable-managed-identity --node-count 1 --ssh-key-value "$SSH" --os-sku Ubuntu --node-vm-size $vmSize
else 
    echo "$(date) - generate a new SSH public key"
    az aks create -g $rg -n $clusterName --enable-managed-identity --node-count 1 --generate-ssh-keys --os-sku Ubuntu --node-vm-size $vmSize
fi

# downloads credentials from the Kubernetes configuration file (default location: ~/.kube/config), and configures the Kubernetes CLI to use them. 
# --overwrite-existing overwrite any existing credentials with the same entry in the Kubernetes configuration file
echo "$(date) - get the credential to access to the cluster: $clusterName"
az aks get-credentials --resource-group $rg --name $clusterName --overwrite-existing

## Enable CSI storage drivers on an existing cluster
az aks update -g $rg -n $clusterName --enable-file-driver 

# Verify the connection to your cluster
kubectl get nodes -o wide
