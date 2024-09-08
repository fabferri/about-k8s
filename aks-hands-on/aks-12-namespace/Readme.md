
<properties
pageTitle= 'AKS hands-on: Namespace'
description= "AKS hands-on: Namespace"
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
   ms.date="08/09/2024"
   ms.author="fabferri" />

# AKS hands-on: namespaces
Kubernetes namespaces are a method by which a single cluster used by an organization can be divided and categorized into multiple sub-clusters and managed individually.<br>
Kubernetes namespaces provide a mechanism for isolating groups of resources, such as pods and deployments, within a single cluster. Names of resources need to be unique within a namespace.
A Kubernetes namespace provides the scope for Pods, Services, and Deployments in the cluster.
<br>
Motivation for using Namespace <br>
A single cluster should be able to satisfy the needs of multiple users or groups of users (henceforth in this document a user community).
Kubernetes namespaces help different projects, teams, or customers to share a Kubernetes cluster.
<br>
Kubernetes starts with four initial namespaces: `default`, `kube-node-lease`, `kube-public`, `kube-system`
A namespace can be in one of two phases: 
- `Active` the namespace is in use
- `Terminating` the namespace is being deleted

<br>

By default, a Kubernetes cluster will instantiate a default namespace when provisioning the cluster to hold the default set of Pods, Services, and Deployments used by the cluster.

<br>

**Hands-on tasks**: <br>
- login in Azure subscription
- create a resource group
- create a cluster
- create a namespace called development
- create a namespace called production
- create pods in each namespace
  - namespace production with custom nginx homepage
  - namespace development with nginx with default homepage
- connect to the nginx from public IP associated with service 

<br>

### <a name="create the full deployment"></a> Run the bash script aks-namespaces.sh
The bash script **aks-namespaces.sh** contains a description of all steps to execute the full deployment.<br>
The script **aks-namespaces.sh** requires you are login in Azure. <br> 
Login in Azure with the device authentication code in the web browser: <br>
`az login --use-device-code` 

Description of the steps executed in **aks-namespaces.sh** <br>
- `az account list --output table`  - Get a list of available subscriptions <br>
- `az account set --subscription $subscription` - Change the active subscription using the subscription name 
- `az account show --output table`              - Show the subscription you are currently using by tabular format <br>
- `az group create --name $rg --location $location` - create a resource group
- `subscriptionId=$(az account list --query "[?name=='$subscription'].id" --output tsv)` - store the default subscription in a variable subscriptionId


```bash
az aks create \
    --name $clusterName \
    --resource-group $rg \
    --location $location \
    --node-count 5 \
    --generate-ssh-keys
```

- `az aks get-credentials --resource-group $rg --name $clusterName` - get AKS credential to connect with kubectl
- `kubectl get nodes -o wide` - get nodes
- `kubectl create namespace <namespace-name>` - create namespace 
- `kubectl get namespaces --show-labels` - list the current namespaces in a cluster
- `kubectl get namespaces <name>` - summary of a specific namespace
- `kubectl describe namespaces <name>` - get detailed information about a namespace
- `kubectl delete namespaces <name>` - delete a namespace
```console
kubectl create namespace $namespace1
kubectl create namespace $namespace2
```


Create a manifest **nginx.yaml** by bash command (it specifies also a Namespace in the YAML declaration in Deployment): 
```bash
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
```

```bash
tee nginx2.yaml <<EOF
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
```
Your active namespace is the "default" namespace. Unless you specify a Namespace in the YAML, all Kubernetes commands will use the active Namespace.

Apply the manifest telling to Kubernetes in which Namespace you want to create your resources.
- `kubectl apply -f nginx1.yaml --namespace=$namespace1` - apply the manifest to the Namespace $namespace1
- `kubectl apply -f nginx2.yaml --namespace=$namespace2` - apply the manifest to the Namespace $namespace2
- `kubectl get deployment --namespace=$namespace1` - viewing deployment in the Namespace $namespace1
- `kubectl get pods --namespace=$namespace1` - get pods in the Namespace $namespace1
- `kubectl get deployment -n=$namespace2` - viewing deployment in the Namespace $namespace2
- `kubectl get pods -n=$namespace2` - get pods in the Namespace $namespace2
- `kubectl get svc -o wide -n=$namespace1` - show the service in  Namespace $namespace1. It shows the public IP and port to connect to the nginx in $namespace1
- `kubectl get svc -o wide -n=$namespace2` - show the service in  Namespace $namespace2. It shows the public IP and port to connect to the nginx in $namespace2

<br>


`Tags: AKS` <br>
`date: 07-09-24`