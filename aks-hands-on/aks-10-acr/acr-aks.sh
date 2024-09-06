#!/bin/bash
#
# create Azure Container Registry (ACR)
#
subscription='AzDev1'
location='uksouth'
rg='k8-1'
rndName=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
acrName="acr${rndName}"
clusterName='aks10'
#
# login with the device authentication code in the web browser
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
#
# 
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "$dt - create an azure container registry: $acrName"
az acr create --resource-group $rg --name $acrName --sku Basic
#
# Import an image from Docker Hub into your ACR
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "$dt - push container images to registry: $acrName"
az acr import \
  --name $acrName \
  --source docker.io/library/nginx:latest \
  --image nginx:v1
#
# View the images in your ACR instance
az acr repository list --name $acrName --output table
#
# show the tag associated with the doker image in the ACR
az acr repository show-tags -n $acrName --repository nginx
#
# Get your login server address 
az acr list --resource-group $rg --query "[].{acrLoginServer:loginServer}" --output table
#
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "$dt - create the AKS cluster: $clusterName" 
#
# Create a new AKS cluster and integrate with an existing ACR 
az aks create -g $rg -n $clusterName  --node-count 2 --enable-managed-identity --generate-ssh-keys --attach-acr $acrName
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
# Create a file called acr-nginx.yaml using the following sample YAML and replace acr-name with the name of your ACR.
tee acr-nginx.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx0-deployment
  labels:
    app: nginx0-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx0
  template:
    metadata:
      labels:
        app: nginx0
    spec:
      containers:
      - name: nginx
        image: $acrName.azurecr.io/nginx:v1
        ports:
        - containerPort: 80

EOF

#
# Run the deployment in your AKS cluster
kubectl apply -f acr-nginx.yaml

# Monitor the deployment
kubectl get pods

# login in the container:
# kubectl exec <POD_NAME> --stdin --tty  -- /bin/bash
# and verify nginx is running.
# Use the following command to check the status:
# service nginx status
# OR
# /etc/init.d/nginx status
# nginx configuration 
# cat /etc/nginx/conf.d/default.conf
#
tee svc.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: public-svc
spec:
  type: LoadBalancer
  selector:
    app: nginx0
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80

EOF
#
kubectl apply -f svc.yaml
kubectl get svc -o wide
# kubectl delete svc <Service_Name>

