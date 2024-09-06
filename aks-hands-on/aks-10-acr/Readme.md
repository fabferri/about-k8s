
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

# AKS hands-on: deployment of ACR
Azure Container Registry (ACR) is a managed registry service based on the open-source Docker Registry 2.0 <br>
ACR is a store to manage your container images and related artifacts.
Tasks of the hands-on:
- login in Azure subscription
- create a ACR
- copy the standard nginx image from [docker registry](https://hub.docker.com/) to the ACR
- create a AKS cluster with nginx docker image stored in the ACR

<br>

### <a name="login in azure subscription"></a> STEP 1: login and connect to the target Azure subscription
- `az login --use-device-code`      - Login in Azure with the device authentication code in the web browser
- `az account list --output table`  - Get a list of available subscriptions <br>
- `az account set --subscription "AzureDev1"` - Change the active subscription using the subscription name 
- `az account show --output table`            - Show the subscription you are currently using by tabular format <br>


### <a name="create the full deployment"></a> STEP 2: run the bash script acr-aks.sh
The script **acr-aks.sh** contains a description of all steps. A description of actions executed by the script is shown below.

- `az group create --name $rg --location $location` - create a resource group
- `az acr create --resource-group $rg --name $acrName --sku Basic` - create a ACR

Import in the ACR the official nginx docker image:
```bash
az acr import \
  --name $acrName \
  --source docker.io/library/nginx:latest \
  --image nginx:v1
```
- `az acr repository list --name $acrName --output table` - view the images in your ACR instance 
- `az acr repository show-tags -n $acrName --repository nginx` -show the tag associated with the doker image in the ACR
- `az aks create -g $rg -n $clusterName  --node-count 2 --enable-managed-identity --generate-ssh-keys --attach-acr $acrName` - Create a new AKS cluster and integrate with an existing ACR 
- `az aks get-credentials --resource-group $rg --name $clusterName` - get AKS credentials to connect to your AKS by kubectl 
- `kubectl get nodes -o wide` - get the list of AKS nodes

Create a manifest file called **acr-nginx.yaml**: 
```bash
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
```

- `kubectl apply -f acr-nginx.yaml` - deployment of  AKS cluster
- `kubectl get pods` - Monitor the deployment

Login in the container by: <br>
- `kubectl exec <POD_NAME> --stdin --tty  -- /bin/bash` <br>
and verify nginx is running: <br>
- `service nginx status` - check the nginx status 
- `/etc/init.d/nginx status` - check the nginx status 
- `cat /etc/nginx/conf.d/default.conf` - check the nginx configuration

Create the manifest file **svc.yaml** to deploy the kubernetes service:
```bash
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
```

- kubectl apply -f svc.yaml - apply the manifest forservice to the cluster
- kubectl get svc -o wide - show the service list
<br>

If you want to delete the service: `kubectl delete svc <Service_Name>`



`Tags: AKS` <br>
`date: 06-09-24`