
<properties
pageTitle= 'AKS hands-on episode 6: MySQL'
description= "AKS hands-on episode 6: MySQL"
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
   ms.date="11/12/2023"
   ms.author="fabferri" />

# AKS hands-on episode 6: MySQL - part 1
The 4th hands-on is about the deployment of MySQL database instance on AKS, using a Persistent Volume dynamically deployed with CSI driver for Azure files. <br>

[![1]][1]

### <a name="login in azure subscription"></a> STEP 1: Login in the Azure subscription and create the Kubernetes cluster
The following setup has been done in Windows host with Azure CLI installed locally.

- `az login --use-device-code` - login with the device authentication code in the web browser
- `az account list --output table` - Get a list of available subscriptions <br>
- `az account show` - Show the subscription you are currently using <br>
- `az account show --output table` - Show the subscription you are currently using by tabular format <br>
- `az account list --query "[?isDefault]" ` - Get the current default subscription <br>
- `az account set --subscription "AzureDemo"` - Change the active subscription using the subscription name 
- `az account list --query "[?name=='AzureDemo'].id" --output tsv` - Get the Azure subscription ID
- `$SubId="$(az account list --query "[?name=='AzureDemo'].id" --output tsv)"; az account set --subscription $SubId`  - Change the active subscription ( in powershell)
- `az aks install-cli` - (<ins>optional</ins>) - One time operation if you do not have aks command installed 
- `az aks create -g $rg -n $clusterName --enable-managed-identity --node-count 3 --ssh-key-value $SSH` - Create the Kubernetes cluster with 3 nodes.
- `az aks get-credentials --resource-group $rg --name $clusterName` - Configure kubectl to connect to the Kubernetes cluster

The powershell script **az-k8s-deployment.ps1** create the resource group, the Kubernetes cluster and the credential to connect to the Kubernetes cluster. 

After cluster creation: 
- `az aks list -o table` - List the properties of Kubernetes cluster: name, Azure region, Resource Group, Kubernetes Version, etc.
- `kubectl get nodes -o wide` - List of the nodes in Kubernetes cluster 
- `kubectl config view` - View the config file 
- `kubectl config get-contexts` - Get all contexts in the file ~\.kube\config
- `kubectl config current-context` - Find the current context
<br>

### <a name="create a storage class"></a> STEP 2: create a storage class
The CSI is a standard for exposing arbitrary block and file storage systems to containerized workloads on Kubernetes. <br>
In Azure Kubernetes Service (AKS) the Container Storage Interface (CSI) driver allows to manage the Azure file shares. <br>
Using CSI drivers in AKS avoids having to touch the core Kubernetes code and wait for its release cycles. <br>
The built-in StorageClasses that uses the Azure Files CSI storage drivers define how an Azure file share is created. <br>
Using the built-in storage classes allows the dynamic provisioning of Azure Files Persistent Volumes. A storage account is automatically created in the node resource group for use with the built-in storage class to hold the Azure files share.
The first task is the creation of the built-in storage class by the **01-storageclass.yaml** manifest file.

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: mysql-sc-azurefile
provisioner: file.csi.azure.com
allowVolumeExpansion: true
mountOptions:
  - file_mode=0777
  - dir_mode=0777
  - uid=999
  - gid=999
  - mfsymlinks
  - actimeo=30
  - cache=strict
  - nobrl
parameters:
  skuName: Standard_LRS
```
The reclaim policy of storage class ensures that the underlying Azure files share is deleted when the respective PV is deleted. <br>
PersistentVolumes that are dynamically created by a StorageClass will have the mount options specified in the **mountOptions** field of the class. <br>
Some comments about the StorageClass:
- `mfsymlinks`: this setting forces the Azure Files mount (Common Internet File System, or cifs) to support symbolic links. <br>
- `nobrl`: This setting prevents sending byte range lock requests to the server. It's necessary for certain applications that break with cifs-style mandatory byte range locks. <br>
- `uid`: linux user identifier. A UID is a number assigned to each Linux user.
- `gid`: linux groups identifier. It is the identifier of the group the user belongs.


Docker creates and populates the directory **/var/lib/mysql** with the user **mysql** image uses. That user, of course, has an uid within the container. That uid happens to be 999.
MySQL Docker image creates and populates the directory **/var/lib/mysql**. The ownership of file stored in the directory is: 
- user **mysql** with uid=999
- group **mysql** with uid=999 

Binding a volume to the mount point **/var/lib/mysql** requires that volume must have the same permissions for the **mysql uid (999)** and **mysql gid (999)** <br>
The StorageClass is used to create the Azure Files Persistent Volume and mount the volume as "**/var/lib/mysql**" <br>
To assign the right ownership to the Persistent Volume, the storage class matches the uid/gid of the mysql user.

[**Note: A setting uid=0 and gid=0 in Storage Class will assign the root user ownership to the Persistent Volume**] <br>


### <a name="Persistent Volume Claim"></a> STEP 3: Persistent Volume Claim
- A PVC is used to automatically provision storage based on a storage class created in STEP 1. A PVC can use one of the pre-created storage classes or a user-defined storage class to create an Azure files share for the desired SKU and size. 
- The Persistent Volume Claim (PVC) customize the amount of allocated storage requested from the storage class created in STEP 1.
- When you create a pod definition, the PVC is specified to request the desired storage.
The second task is to apply the **02-pvc.yaml** manifest file.



### <a name="connecto to the AKS cluster"></a> STEP 4: Deployment of MySQL
The third task is to create the deployment specified in the **03-mysql-deployment.yaml** manifest file.
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql        # The name "mysql" is assigned to this Deployment
spec:                # This section describes the specifications for the Deployment.
  selector:          # It specifies how the Deployment selects which Pods to manage.
    matchLabels:     # This section defines the labels that the Deployment uses to select Pods to manage
      app: mysql     # The Deployment selects Pods with the label "app" equal to "mysql."
  strategy:
    type: Recreate   # It defines the update strategy for the Deployment. “Recreate,” meaning the existing Pods are terminated and new ones are created during updates.
  template:          # This section describes the Pod template for the Deployment.
    metadata:
      labels:
        app: mysql
    spec:
      containers:              # This is an array of containers running in the Pod. In this case, there is one container.
      - image: mysql:8.2       # It specifies the Docker image to use for the container, which is the 8.2 version of MySQL.
        name: mysql            # The name of the container is "mysql"
        env:                   # This section defines environment variables for the container.
        - name: MYSQL_ROOT_PASSWORD
          value: 'test***12345'           # MySQL root password in cleartext between ''
        ports:
        - containerPort: 3306             # Port 3306 is opened for MySQL connections.
          name: mysql
        volumeMounts:                     # This section defines where to mount volumes in the container.
        - name: mysql-persistent-storage  # It specifies the volume name
          mountPath: /var/lib/mysql       # The path within the container where the volume will be mounted. This is typically the location where MySQL stores its data.
      volumes:                            # This section specifies the volumes to be used in the Pod.
      - name: mysql-persistent-storage    # The name of the volume matches the one specified in volumeMounts.
        persistentVolumeClaim:            # It references a PersistentVolumeClaim (PVC) named "mysql-pv-claim". The PVC provides storage resources for the Pod.
          claimName: mysql-pv-claim
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  ports:
  - port: 3306   # Port 3306 is exposed, which corresponds to the port that MySQL uses for database connections.
  type: ClusterIP
  selector:      # It selects the Pods to forward network traffic to.
    app: mysql   # The Service forwards traffic to Pods with the label "app" equal to "mysql". These are the Pods managed by the "mysql" Deployment.

```

### <a name="check the POD status"></a> STEP 5: check the deployment status
After applying the manifest files:

    kubectl apply -f 01-storageclass.yaml
    kubectl apply -f 02-pvc.yaml
    kubectl apply -f 03-mysql-deployment.yaml

Run the commands for checking the deployment:

```console
kubectl get pod
kubectl get pod --watch
kubectl describe pod <PodName>
kubectl logs <PodName>
```
POD should be in running <br>

For log details see the file: **logs.txt**


### <a name="Connect to the container"></a> STEP 6: Connect to the POD
Login in the container: 
```console
kubectl exec --stdin --tty <PodName> -- /bin/bash 
```
<br>

Inside the container check the volume for the mount point **/var/lib/mysql**
```
bash-4.4# df -h
Filesystem                                                                                Size  Used Avail Use% Mounted on
overlay                                                                                   124G   23G  102G  19% /
tmpfs                                                                                      64M     0   64M   0% /dev
/dev/root                                                                                 124G   23G  102G  19% /etc/hosts
shm                                                                                        64M     0   64M   0% /dev/shm
//f85c493fa84f54ab1b74613.file.core.windows.net/pvc-ec3e10cc-a29e-4477-9e67-daf36d04e516   60G  193M   60G   1% /var/lib/mysql
tmpfs                                                                                     5.3G   12K  5.3G   1% /run/secrets/kubernetes.io/serviceaccount
tmpfs                                                                                     3.9G     0  3.9G   0% /proc/acpi
tmpfs                                                                                     3.9G     0  3.9G   0% /proc/scsi
tmpfs                                                                                     3.9G     0  3.9G   0% /sys/firmware
```
the folder **/var/lib/mysql** is mounted to the 60Gi PVC associated with the Azure file. 

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

Create and run an ubuntu image, version 22.04:
```bash
kubectl run myubuntu --image ubuntu:22.04 --command -- sleep 100000000000000
```

Login to the ubuntu container:
```bash
kubectl exec --stdin --tty myubuntu -- /bin/bash 
```

Inside the ubuntu container install the mysql client:
```bash
apt update
apt install mysql-client
```

Inside the ubuntu container check the MySQL client version: `mysql --version` <br>
Connect to the MySQL server container:

```Console
mysql -u root -p'test***12345' -h 10.0.120.138 -P 3306 
```

> [!NOTE] 
> - **no space after -p**
> - The **root** password to access to MySQL is in the file **03-mysql-deployment.yaml**
> - you can get the IP Address and TCP port of MySQL server container by command:
```console
kubectl get service
NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
kubernetes   ClusterIP   10.0.0.1       <none>        443/TCP    18m
mysql        ClusterIP   10.0.120.138   <none>        3306/TCP   9m36s
```



### <a name="Caveats"></a>Caveats
- This specific deployment is intended for a single MySQL instance, implying that it cannot be expanded to multiple Pods; it operates exclusively with one Pod.
- This deployment lacks support for rolling updates, necessitating the constant configuration of spec.strategy.type as "Recreate".
- The manifest file **03-mysql-deployment.yaml** does not follow the best pratice becasue the passoword of user **root** in MySQL should be written in specific manifest file

## <a name="Command list"></a> Command list

### kubectl apply commands in order
    kubectl apply -f 01-storageclass.yaml
    kubectl apply -f 02-pvc.yaml
    kubectl apply -f 03-mysql-deployment.yaml

### kubectl get commands
    kubectl get pod
    kubectl get pod --watch
    kubectl get pod -o wide
    kubectl get service
    kubectl get all | grep mysql

### kubectl debugging commands
    kubectl describe pod mysql-xxxxxx
    kubectl describe service mysql-service
    kubectl logs mysql

### kubectl delete all the deployment
    kubectl delete -f .


<br>

`Tags: aks` <br>
`date: 19-12-23`

<!--Image References-->

[1]: ./media/01.png "AKS diagram"

<!--Link References-->