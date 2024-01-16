
<properties
pageTitle= ' AKS hands-on: MySQL - part 2'
description= "AKS hands-on: MySQL - part 2"
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

#  AKS hands-on: MySQL - part 2
In the [AKS hands-on: MySQL - part 1](https://github.com/fabferri/about-k8s/tree/main/aks-hands-on/aks-06-mysql-part1) is described how to deploy a MySQL using a Permant Volume with Azure file. This hands-on assumes that you have read and run the part 1 and yu have acquired the the concepts of build-in StorageClass and Permant Volume.
<br>

In this hands-on the MySQL root password is stored in the **03-mysql-secret.yaml** manifest file.


### <a name="Creation of the AKS cluster"></a>1. Creation of the AKS cluster
The powershell script **az-k8s-deployment.ps1** create the resource group, the AKS cluster and the credential to connect to the Kubernetes cluster.

### <a name="full deployment"></a>2. Apply in order the commands to create the MySQL deployment

    kubectl apply -f 01-storageclass.yaml
    kubectl apply -f 02-pvc.yaml
    kubectl apply -f 03-mysql-secret.yaml
    kubectl apply -f 04-mysql-deployment.yaml


### <a name="create a storage class"></a>3. Secrets
Secrets are specifically intended to hold confidential data. When creating a Secret, you can specify its type using the type field of the Secret resource. <br>
Kubernetes provides several built-in secret types; i.e.:
- **Opaque**: it is a built-in secret type for arbitrary user-defined data
- **kubernetes.io/basic-auth**: it is a built-in secret type to store credentials for basic authentication. 

The basic authentication Secret type is provided only for convenience. <br>
You can create an Opaque type for credentials used for basic authentication. However, using the defined and public Secret type (kubernetes.io/basic-auth) helps easily to understand the purpose of the Secret.

In **03-mysql-secret.yaml** is used the <ins>basic authentication</ins> Secret type:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
type: kubernetes.io/basic-auth
stringData:
  username: root            # required field for kubernetes.io/basic-auth
  password: test***12345    # required field for kubernetes.io/basic-auth
```
In **type:kubernetes.io/basic-auth**, utilization of **stringData** requires as mandatory the fields **username** and **password** in cleartext format.

The manifest **04-mysql-deployment.yaml** reference the MySQL docker image in dockerhub: https://hub.docker.com/_/mysql <br>
As reported in the dockerhub documentation: <br>
When you start the mysql image, you can adjust the configuration of the MySQL instance by passing one or more environment variables.
**MYSQL_ROOT_PASSWORD** : it is a mandatory environment variable  and specifies the password that will be set for the MySQL root superuser account. <br>
In the Secret manifest file **03-mysql-secret.yaml**, the field **password** specifies the password of the MySQL root superuser account.

### <a name="check the POD status"></a>4: Check the deployment status
Run the commands for checking the deployment:

```console
kubectl get pod
kubectl get pod --watch
kubectl describe pod <PodName>
kubectl logs <PodName>
```

Login in the container: 
```console
kubectl exec --stdin --tty <PodName> -- /bin/bash 
```
<br>

Inside the container by linux command **df -h** check the volume for the mount point **/var/lib/mysql**
<br>
Inside the container, connect to MySQL:

```console
bash-4.4# mysql -p
```
When prompted, enter the password

```console
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
4 rows in set (0.00 sec)

mysql>
```

### delete all the deployment
    kubectl delete -f .

`Tags: AKS` <br>
`date: 11-12-23`

