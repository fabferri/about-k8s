#!/bin/bash
#
# create namespaces
#
subscription='AzDev1'
location='uksouth'
rg='k8-12'
clusterName='aks12'
namespace1='production'
namespace2='development'

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
    --node-count 5 \
    --generate-ssh-keys 
#
# get AKS credentials 
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "$dt - get the credential to access to the cluster: $clusterName"
az aks get-credentials --resource-group $rg --name $clusterName 
#
# ***** Note: if not installed locally, run the command to install kubectl
#  az aks install-cli 
#
echo "get the list of customer nodes:"
kubectl get nodes -o wide
#
#
kubectl create namespace $namespace1
kubectl create namespace $namespace2
kubectl get namespaces $namespace1
kubectl get namespaces $namespace2
kubectl describe namespaces $namespace1
kubectl describe namespaces $namespace2
kubectl get namespaces --show-labels

# Create a file called nginx.yaml using the following sample YAML 
# it also specify a Namespace in the YAML declaration in Deployment
tee nginx1.yaml <<EOF
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
  namespace: $namespace1
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

tee nginx1.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 # tells deployment to run 2 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: public-svc
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - name: http
    protocol: TCP
    port: 8080     
    targetPort: 80 

EOF

# apply the manifest telling to Kubernetes in which Namespace you want to create your resources.
kubectl apply -f nginx1.yaml --namespace=$namespace1 
kubectl apply -f nginx2.yaml --namespace=$namespace2 
# Viewing resources in the Namespace
kubectl get deployment --namespace=$namespace1
kubectl get pods --namespace=$namespace1
kubectl get deployment -n=$namespace2
kubectl get pods -n=$namespace2
#
kubectl get svc -o wide -n=$namespace1
kubectl get svc -o wide -n=$namespace2


