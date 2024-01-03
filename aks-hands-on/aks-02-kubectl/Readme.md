
<properties
pageTitle= 'AKS hands-on episode 2: imperative commands'
description= "AKS hands-on episode 2: imperative"
services="AKS"
documentationCenter="https://github.com/fabferri/"
authors="fabferri"
editor="fabferri"/>

<tags
   ms.service="AKS"
   ms.devlang="AKS"
   ms.topic="article"
   ms.tgt_pltfrm="AKS"
   ms.workload="AKS"
   ms.date="19/12/2023"
   ms.author="fabferri" />

# AKS hands-on episode 2: imperative commands

**kubectl** is a Kubernetes command line tool for communicating with a Kubernetes cluster's control plane, using the Kubernetes API.
The **kubectl** command-line tool supports several different ways to create and manage Kubernetes objects:
- **Imperative commands**. Using imperative commands, a user operates directly on live objects in a cluster. This is the recommended way to get started or to run a one-off task in a cluster. 
- **Imperative object configuration**. The **kubectl** command specifies the operation (create, replace, etc.), optional flags and at least one file name. The file specified must contain a full definition of the object in YAML or JSON format. A YAML (or JSON) file, named manifest, must contain a full definition of the objects. Objects configuration requires basic understanding of the object schema for writing correct YAML files.
Using imperative command is faster and less prone to errors than declarative. <br>
- **declarative**. A user operates on object configuration files stored locally. **kubectl** detects automatically per-object operation of create, update, and delete operations. <br>

See the [official Kubernetes documentation](https://kubernetes.io/).

The article walks you through some basic useful **kubectl** commands. <br>
Below a list of commands discussed in this post.
- `kubectl run`: it is used only to creates 1 or more instances of a container image on your cluster.
- `kubectl create`: it is used to create different type of Kubernetes resources (i.e. deployments, replicasets, services, etc.)

Examples: <br>
- `kubectl run mypod --image=nginx` : Create a pod with nginx image
- `kubectl get pod` : show the pods
- `kubectl get pod -o yaml` : show the pod in yaml format. it contains information about the status of the pod.
- `kubectl run mypod --image=nginx -o yaml --dry-run=client` : the **--dry-run=client** flag shows the preview the object that would be sent to your cluster, without really submitting it.
- `kubectl create --help` : show all the option can be used with the command
- `kubectl create deploy my-deploy --image=nginx --replicas=1`: create the deployment
- `kubectl get deploy` : get the deployment

Subcommands: <br>
- `kubectl set` : modify the image in the deployment
- `kubectl label`
- `kubectl scale` : scale out/shrink the number of POD
- `kubectl edit`

examples: <br>
- `kubectl set image deploy my-deploy *=nginx:1.19` : set a specific image version, i.e. update the image of existing deployment <br>
- `kubectl describe pod my-deploy-xxxx`  : check the deployment
- `kubectl describe pod my-deploy-xxxxx | grep -i image` : filtering the command outcome by grep to discover the image of the pod
- `kubectl set --help` : help to see all the options with set command

- `kubectl scale deploy my-deploy --replicas=2` : scale the deployment from 1 to 2
- `kubectl rollout status deploy my-deploy` : to check if the pod has been successful rollout
- `kubectl rollout history deploy my-deploy` : see the change. if the change has not been recorded the filed is empty
- `kubectl edit deploy my-deploy` : editor is open, we can change the attribute we want

- `kubectl get <resource> --show-labels` : it shows the labels apply to the resource, i.e. pods
- `kubectl get <resource> -o wide` : more details about the specific resources

- `kubectl get pod -o wide`   : show the IP of the POD
- `kubectl get node -o wide`  : show the IP of the nodes
- `kubectl get node --show-labels` : show the labels assigned to the nodes
- `kubectl expose pod mypod --name mypod-svc --port=80`    : to see the selector for 
- `kubectl get svc`  : show the service
- `kubectl get svc -o wide` : show the service including selector
- `kubectl describe pod mypod | grep -i image` : to see the image running in the POD
- `kubectl describe pod mypod | grep -i image -A 2` : to see the image running in the POD with subsequent two lines
- `kubectl get pod mypod -o jsonpath='{.spec.containers[*].image}'` : to see the image in the pod
- `kubectl delete pod mypod --force`   : terminate fast the pod. Without --force takes longer for timeout and graceful delete
- `kubectl explain pod.spec.containers` : gets documentation of various resources
   `kubectl explain pod.spec.containers.readinessProbe` <br>
   `kubectl explain pod.spec.containers.readinessProbe.httpGet` <br>



### Create a pod yaml file without actually creating the pod
On day-to-day operations in Kubernetes, it is frequent utilization of the **kubectl flag --dry-run=client** to generate definitions of objects in yaml. By pairing it with **-o yaml**, you can printout the yaml file on the terminal:
```bash
kubectl run nginx --image=nginx --dry-run=client -o yaml
```
This will output a yaml file you can then apply/create or update a pod as needed:
```
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nginx
  name: nginx
spec:
  containers:
  - image: nginx
    name: nginx
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

For more [details and command output](./show-commands.md)





`Tags: AKS` <br>
`date: 11-12-23`

