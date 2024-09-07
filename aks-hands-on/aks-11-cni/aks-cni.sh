#!/bin/bash
#
# create Azure Container Registry (ACR)
#
subscription='AzDev1'
location='uksouth'
rg='k8-11'
clusterName='aks11'
vnetName='vnet1'
subnet1Name='node1subnet'
subnet2Name='pod1subnet'
subnet3Name='node2subnet'
subnet4Name='pod2subnet'
nodePoolName='nodepool2'
#
# login with the device authentication code in the web browser:
# az login --use-device-code
#
echo 'Select the azure subscription' 
az account set --subscription $subscription
#
# verify the set subscription
az account show
#
echo "create the resource group: $rg" 
az group create --name $rg --location $location
#
# store the default subscription in a variable subscriptionId
subscriptionId=$(az account list --query "[?name=='$subscription'].id" --output tsv)
echo "subscription ID: $subscriptionId"
# 
# Create our two subnet network 
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "$dt - create vnet: $vnetName and subnets: $subnet1Name , $subnet2Name"
az network vnet create --resource-group $rg --location $location --name $vnetName --address-prefixes 10.0.0.0/8 -o none 
az network vnet subnet create --resource-group $rg --vnet-name $vnetName --name $subnet1Name --address-prefixes 10.240.0.0/16 -o none 
az network vnet subnet create --resource-group $rg --vnet-name $vnetName --name $subnet2Name --address-prefixes 10.241.0.0/16 -o none 
#
#
# Create the cluster, referencing the node subnet using --vnet-subnet-id and the pod subnet using --pod-subnet-id 
# the cluster is created without the monitor add-on: --enable-addons monitoring
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "$dt - create the AKS: $clusterName"
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

# Adding node pool to the AKS
# A node pool is a group of nodes within a cluster that all have the same configuration
# When you create a cluster, the number of nodes and type of nodes that you specify are used to create the first node pool of the cluster. 
# Then, you can add additional node pools of different sizes (SKU) and types to your cluster. 
# All nodes in any given node pool are identical to one another.
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "$dt - Adding node pool to the AKS: $clusterName"
az network vnet subnet create --resource-group $rg --vnet-name $vnetName --name $subnet3Name --address-prefixes 10.242.0.0/16 -o none 
az network vnet subnet create --resource-group $rg --vnet-name $vnetName --name $subnet4Name --address-prefixes 10.243.0.0/16 -o none 
az aks nodepool add --cluster-name $clusterName --resource-group $rg --name $nodePoolName \
    --max-pods 10 \
    --node-count 3 \
    --node-vm-size Standard_D2s_v4 \
    --zones 1 2 3 \
    --vnet-subnet-id /subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Network/virtualNetworks/$vnetName/subnets/$subnet3Name \
    --pod-subnet-id /subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Network/virtualNetworks/$vnetName/subnets/$subnet4Name 


# To view the nodepools:
az aks nodepool list --cluster-name $clusterName --resource-group $rg -o table
#
subnet1Id=$(az network vnet subnet show --resource-group $rg --vnet-name $vnetName --name $subnet1Name --query id --output tsv)
subnet2Id=$(az network vnet subnet show --resource-group $rg --vnet-name $vnetName --name $subnet2Name --query id --output tsv)
subnet3Id=$(az network vnet subnet show --resource-group $rg --vnet-name $vnetName --name $subnet3Name --query id --output tsv)
subnet4Id=$(az network vnet subnet show --resource-group $rg --vnet-name $vnetName --name $subnet4Name --query id --output tsv)
echo $subnet1Id
echo $subnet2Id
echo $subnet3Id
echo $subnet4Id
# Remove a nodepool: 
# az aks nodepool delete --cluster-name $clusterName --resource-group $rg --name $nodePoolName
# 
#
# get AKS credentials 
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "$dt - get the credential to access to the cluster: $clusterName"
az aks get-credentials --resource-group $rg --name $clusterName 
#
echo "get the list of customer nodes:"
kubectl get nodes -o wide
#
# Create a file called nginx.yaml using the following sample YAML and replace acr-name with the name of your ACR.
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

# By default, if we deploy a pod into the cluster, it could be deployed into any of the 2 nodepools.
#  we can choose to target a specific nodepool using Labels on nodepools and nodeSelector from deployment/pods
#
# Run the deployment in your AKS cluster
kubectl apply -f nginx.yaml
#
kubectl get node -o wide
# monitor the deployment
kubectl get pods -o wide
#
kubectl get svc -o wide
# kubectl delete svc <Service_Name>

