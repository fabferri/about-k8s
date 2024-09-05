#!/bin/bash
location='uksouth'
rg='k8-1'
clusterName='aks5'
#
echo 'Select the azure subscription' 
az account set --subscription 'AzDev1'
#
echo "create the resource group: $rg" 
az group create --name $rg --location $location
#
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "$dt - create the AKS cluster: $clusterName" 

az aks create -g $rg -n $clusterName  --node-count 2 --enable-managed-identity --generate-ssh-keys 
# 
##
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "$dt - get the credential to access to the cluster: $clusterName"
az aks get-credentials --resource-group $rg --name $clusterName 

## Enable CSI storage drivers on an existing cluster
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "$(date) - update the cluster: $clusterName" 
az aks update -g $rg -n $clusterName --enable-file-driver 