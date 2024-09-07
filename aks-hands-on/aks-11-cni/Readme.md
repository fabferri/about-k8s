
<properties
pageTitle= 'AKS hands-on: Deployment'
description= "AKS hands-on: Deployment"
services="AKS"
documentationCenter="https://github.com/fabferri/"
authors="fabferri"
editor=""/>

<tags
   ms.service="AKS"
   ms.devlang="AKS"
   ms.topic="article"
   ms.tgt_pltfrm="AKS"
   ms.workload="AKS"
   ms.date="06/09/2024"
   ms.author="fabferri" />

# AKS hands-on: Azure CNI with dynamic allocation of IPs in AKS
With Azure Container Networking Interface (CNI), every pod gets an IP address from the subnet and can be accessed directly. Systems in the same vnet as the AKS cluster see the pod IP as the source address for any traffic from the pod. Each node has a configuration parameter for the maximum number of pods that it supports. The equivalent number of IP addresses per node are then reserved up front for that node. <br>
When you create an AKS cluster for Azure CNI networking are required:
- a vnet which you want to deploy the  cluster.
- the subnet within the virtual network where you want to deploy the cluster
Specification of Kubernetes service address range (set of virtual IPs that Kubernetes assigns to internal services in your cluster) is not mandatory.

<br>
Tasks of the hands-on:
- login in Azure subscription
- create a resource group
- use Azure CNI networking to create and use a virtual network subnets for an AKS cluster. <br> 
  A flat network is used which nodes and pods receive IPs from your subnets. <br>
  Two separate subnets are used: Azure CNI Pod Subnet and Azure CNI Node subnet. <br>
  A Dynamic IP Allocation mode is used.
- create an AKS cluster
- add a node pool to the cluster. A node pool is a group of nodes within a cluster that all have the same configuration. <br>
  When you create a cluster, the number of nodes and type of nodes that you specify are used to create the first node pool of the cluster. <br> 
  Then, you can add additional node pools of different sizes (SKU) and types to your cluster. All nodes in any given node pool are identical to one another.
- show the node pools
- create a manifest file **nginx.yaml** to deploy nginx to the AKS cluster
- connect to the nginx from public IP associated with service 

<br>

> [!Note]
> Nodes of the same configuration are grouped together into node pools. Node pools contain the underlying VMs that run your applications. 
> System node pools and user node pools are two different node pool modes for your AKS clusters. System node pools serve the primary purpose of hosting critical system pods such as CoreDNS and metrics-server. 
> User node pools serve the primary purpose of hosting your application pods. 
> However, application pods can be scheduled on system node pools if you wish to only have one pool in your AKS cluster. 
> Every AKS cluster must contain at least one system node pool with at least two nodes.


### <a name="create the full deployment"></a> Run the bash script aks-cni.sh
The bash script **aks-cni.sh** contains a description of all steps to execute the full deployment.<br>
The script **aks-cni.sh**requires you are login in Azure; login in Azure with the device authentication code in the web browser:
`az login --use-device-code` 

Description of the steps executed in **aks-cni.sh** <br>
- `az account list --output table`  - Get a list of available subscriptions <br>
- `az account set --subscription $subscription` - Change the active subscription using the subscription name 
- `az account show --output table`              - Show the subscription you are currently using by tabular format <br>
- `az group create --name $rg --location $location` - create a resource group
- `subscriptionId=$(az account list --query "[?name=='$subscription'].id" --output tsv)` - store the default subscription in a variable subscriptionId
- `az network vnet create --resource-group $rg --location $location --name $vnetName --address-prefixes 10.0.0.0/8 -o none` -create a vnet 
- `az network vnet subnet create --resource-group $rg --vnet-name $vnetName --name $subnet1Name --address-prefixes 10.240.0.0/16 -o none ` - create a subnet1 for CNI Node
- `az network vnet subnet create --resource-group $rg --vnet-name $vnetName --name $subnet2Name --address-prefixes 10.241.0.0/16 -o none`  - create a subnet2 for CNI Pod
- Create the cluster, referencing <br>
  the node subnet using `--vnet-subnet-id` <br> 
  the pod subnet using `--pod-subnet-id` <br>
```bash
az aks create \
    --name $clusterName \
    --resource-group $rg \
    --location $location \
    --max-pods 250 \
    --node-count 2 \
    --network-plugin azure \
    --vnet-subnet-id /subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Network/virtualNetworks/$vnetName/subnets/$subnet1Name \
    --pod-subnet-id /subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Network/virtualNetworks/$vnetName/subnets/$subnet2Name \
    --generate-ssh-keys
```
> [!Note] 
> the AKS cluster is created without the monitor add-on: --enable-addons monitoring

- `az network vnet subnet create --resource-group $rg --vnet-name $vnetName --name $subnet3Name --address-prefixes 10.242.0.0/16 -o none` - create a subnet3 for CNI Node of the node pool
- `az network vnet subnet create --resource-group $rg --vnet-name $vnetName --name $subnet4Name --address-prefixes 10.243.0.0/16 -o none` - create a subnet2 for CNI Pod of the node pool
- Adding a node pool to the AKS:
```bash
az aks nodepool add --cluster-name $clusterName --resource-group $rg --name $nodePoolName \
    --max-pods 10 \
    --node-count 3 \
    --node-vm-size Standard_D2s_v4 \
    --zones 1 2 3 \
    --vnet-subnet-id /subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Network/virtualNetworks/$vnetName/subnets/$subnet3Name \
    --pod-subnet-id /subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Network/virtualNetworks/$vnetName/subnets/$subnet4Name 
```
- `az aks nodepool list --cluster-name $clusterName --resource-group $rg -o table` - view the node pools
```console
az aks nodepool list --cluster-name $clusterName --resource-group $rg -o table
Name       OsType    KubernetesVersion    VmSize           Count    MaxPods    ProvisioningState    Mode
---------  --------  -------------------  ---------------  -------  ---------  -------------------  ------
nodepool1  Linux     1.29                 Standard_DS2_v2  2        250        Succeeded            System
nodepool2  Linux     1.29                 Standard_D2s_v4  3        10         Succeeded            User
```
- `az aks get-credentials --resource-group $rg --name $clusterName` - get AKS credential to connect with kubectl
- `kubectl get nodes -o wide` - get nodes
```console
kubectl get node -o wide
NAME                                STATUS   ROLES    AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
aks-nodepool1-11400876-vmss000000   Ready    <none>   9m25s   v1.29.7   10.240.0.4    <none>        Ubuntu 22.04.4 LTS   5.15.0-1071-azure   containerd://1.7.20-1
aks-nodepool1-11400876-vmss000001   Ready    <none>   9m22s   v1.29.7   10.240.0.5    <none>        Ubuntu 22.04.4 LTS   5.15.0-1071-azure   containerd://1.7.20-1
aks-nodepool2-34291456-vmss000000   Ready    <none>   4m32s   v1.29.7   10.242.0.5    <none>        Ubuntu 22.04.4 LTS   5.15.0-1071-azure   containerd://1.7.20-1
aks-nodepool2-34291456-vmss000001   Ready    <none>   4m18s   v1.29.7   10.242.0.6    <none>        Ubuntu 22.04.4 LTS   5.15.0-1071-azure   containerd://1.7.20-1
aks-nodepool2-34291456-vmss000002   Ready    <none>   4m19s   v1.29.7   10.242.0.4    <none>        Ubuntu 22.04.4 LTS   5.15.0-1071-azure   containerd://1.7.20-1
```


Create a manifest **nginx.yaml** by bash command: 
```bash
tee nginx.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: index-html-configmap
data:
  index.html: |
    <html>
    <h1>Welcome</h1>
    </br>
    <h1>Hi! This is a simple test. </h1>
    </html>

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: default
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 3
  strategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:stable
        ports:
        - containerPort: 80
          name: http-web-svc
        volumeMounts:
            - name: nginx-index-file
              mountPath: /usr/share/nginx/html/
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5    
      volumes:
      - name: nginx-index-file
        configMap:
          name: index-html-configmap

---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: http-web-svc
    nodePort: 30036

EOF
```

- `kubectl apply -f nginx.yaml` - deployment of manifest file
- `kubectl get pods` - view the deployment
```console
kubectl get pods -o wide
NAME                                READY   STATUS    RESTARTS   AGE     IP            NODE                                NOMINATED NODE   READINESS GATES
nginx-deployment-5bd95c8544-c647p   1/1     Running   0          3m11s   10.243.0.6    aks-nodepool2-34291456-vmss000000   <none>           <none>
nginx-deployment-5bd95c8544-m7sdn   1/1     Running   0          3m11s   10.241.0.12   aks-nodepool1-11400876-vmss000000   <none>           <none>
nginx-deployment-5bd95c8544-qzb5l   1/1     Running   0          3m11s   10.241.0.33   aks-nodepool1-11400876-vmss000001   <none>           <none>
```
- `kubectl get svc -o wide` - show the service list. it shows the public IP to connect to the nginx.
<br>


`Tags: AKS` <br>
`date: 07-09-24`