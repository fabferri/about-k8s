
<properties
pageTitle= 'AKS hands-on: WordPress'
description= "AKS hands-on: WordPress"
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


# AKS hands-on: WordPress
WordPress is a popular Content Management System (CMS) that allows you to create and manage websites easily. <br>
This hands-on will walk you through setting up WordPress on an AKS cluster using a MySQL StatefulSet for database storage.
The hands-on provides you with the necessary deployment files, secret files, Persistent Volume (PV) and Persistent Volume Claim (PVC) files, and service files to start the application. <br>
WordPress uses MySQL as database management system to store, retrieve, and display all the content that you create on your website. This includes posts, pages, comments, and more. <br>
The configuration of WordPress on a AKS cluster using a MySQL StatefulSet provides data persistence and scalability for the WordPress website. 

### <a name="file list"></a>1. File list

|  file name                 | description                                                    |
| -------------------------- | -------------------------------------------------------------- |
| **az-aks.sh**              | bash script to create the AKS cluster                          |
| **apply.sh**               | bash script to apply bulk operation for the full configuration. Run this script to create the WordPress   |
| **mysql-secret.yaml**      | manifest file to store the MySQL root password                 |
| **mysql-pv.yaml**          | persist volume 20Gi and persistent volume claim. <br> The persist volume defines a volume mount for **/var/lib/mysql** |
| **mysql.yaml**             | defines a MySQL StatefulSet with a single replica, using a Persistent Volume Claim (PVC) for data storage |
| **wordpress-pv.yaml**      | manifest file to create persistent volume and persisten volume clain for the wordpress application        |
| **wordpress-deployment.yaml** | manifest file to create the wordpress application           |



### <a name="MySQL StatefulSet"></a>2. Create MySQL StatefulSet
To successfully deploy a MySQL instance on Kubernetes, create a series of YAML files that you will use to define the following Kubernetes objects:
- a Kubernetes secret for storing the MySQL database password.
- a Persistent Volume (PV) to allocate storage space for the database.
- a Persistent Volume Claim (PVC) that will claim the PV for the deployment.
- a Kubernetes Service
- the MySQL deployment itself. You can run a stateful application by creating a Kubernetes StatefulSet and connecting it to an existing PersistentVolume using a PersistentVolumeClaim. 

#### <a name="MySQL StatefulSet"></a> Step 1: Create Kubernetes Secret
The MySQL root password is fetched from a secret manifest **mysql-secret.yaml**. The  secret file has **type: Opaque**, then the MySQL root password is stored in the file with base64 encode format: 
```bash
echo TXlBZG1pblBhc3N3b3JkMDE= | base64 --decode
echo -n 'MyAdminPassword01' | base64
```


#### <a name="PV and PVC"></a> Step 2: Create Persistent Volume and Volume Claim
A PersistentVolume (PV) is a piece of storage in the cluster that has been 
- <ins>manually</ins> provisioned by an administrator, 
<br> or 
- <ins>dynamically</ins> provisioned by Kubernetes using a StorageClass. 

A PersistentVolumeClaim (PVC) is a request for storage by a user that can be fulfilled by a PV. PersistentVolumes and PersistentVolumeClaims are independent from Pod lifecycles and preserve data through restarting, rescheduling, and even deleting Pods. <br>
Persistent Volume Claims are a way for an application developer to request storage for the application without having to know where the underlying storage is.
When you deploy a claim, kubernetes will try to find a PV that matches the claim criteria and then bound it to the PVC, and it will not be released until the PVC is deleted. <br>

In Kubernetes:
- You can mark a **StorageClass** as the default for your cluster. 
- If you set the **storageclass.kubernetes.io/is-default-class** annotation to **true** on more than one StorageClass in your cluster, and you then create a  PersistentVolumeClaim with no storageClassName set, Kubernetes uses the most recently created default StorageClass.
- When a PVC does not specify a **storageClassName**, the default StorageClass is used.

To check if a default StorageClass is set:
```bash
kubectl get storageclass default -o=jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' ; echo ''
true
```

List the StorageClasses in the AKS cluster:
```Console
kubectl get storageclass
NAME                    PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
azurefile               file.csi.azure.com   Delete          Immediate              true                   160m
azurefile-csi           file.csi.azure.com   Delete          Immediate              true                   160m
azurefile-csi-premium   file.csi.azure.com   Delete          Immediate              true                   160m
azurefile-premium       file.csi.azure.com   Delete          Immediate              true                   160m
default (default)       disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   160m
managed                 disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   160m
managed-csi             disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   160m
managed-csi-premium     disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   160m
managed-premium         disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   160m
```
In the list above, the default StorageClass is marked by **(default)**. <br>
For AKS the default storage class is provide through the CSI driver **disk.csi.azure.com** 
<br> <br>

In our case the PV and PVC objects are defined in **mysql-pv.yaml** <br>
if you define **storageClassName: manual** in spec of yaml file for PV, it also needs to be defined for PVC. This SC manual won't get created and is used to bind persistent volume claim requests to this persistent volume.



#### <a name="PV and PVC"></a> Step 3: Create MySQL Deployment 
The YAML file **mysql.yaml** describes a StatefulSet that runs MySQL and references the PersistentVolumeClaim (PVC). The file defines a volume mount for **/var/lib/mysql**, and then creates a **PersistentVolumeClaim** that looks for a 20G volume. This claim is satisfied by any existing volume that meets the requirements, or by a dynamic provisioner.

Inside **mysql.yaml** is defined the Service:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  ports:
  - port: 3306
  selector:
    app: mysql
  type: ClusterIP
```

the **type: ClusterIP** in the Service assigns an IP address from a pool of IP addresses that your cluster has reserved for that purpose. This type of service works as expected for internal communication between MySQL and WordPress.


To apply the configurations MySQL (with StatefulSet API), run the following commands:
```Console
kubectl apply -f mysql-secret.yaml
kubectl apply -f mysql-pv.yaml
kubectl apply -f mysql.yaml
```



### <a name="MySQL verification"></a>4. MySQL verification
Display the pod name and connect to the container:
```
kubectl get pod
kubectl exec -i -t <podname> -- /bin/bash
```
<br>

Inside the container, to login in MySQL: 
```bash
mysql -u root -p
```
Check the consistency with the following commands:
```sql
SHOW databases;                   -- show DBs
SELECT * FROM mysql.user;         -- information about MySQL users
DESC mysql.user;                  -- display a preview of user table columns
SELECT user,host FROM mysql.user; -- see the MySQL users and which host or IP address they have permission to access.
SELECT current_user();
SELECT user,host, command FROM information_schema.processlist;  -- display currently logged-in users with their states. 
```

### <a name="WordPress Deployment"></a>5. Create WordPress Deployment
To ensure data persistence for the WordPress, **wordpress-pv.yaml** create <ins>Persistent Volumes</ins> and <ins>Persistent Volume Claims</ins>.  <br>
The **hostPath** in the Persistent Volume definition points to a suitable directory **"/home/ubuntu/project/wp-data"** in Kubernetes nodes.
A **hostPath** PersistentVolume uses a file or directory on the Node to emulate network-attached storage.
In a production cluster, you would not use **hostPath**. Instead a cluster administrator would provision a network resource like a Azure persistent disk, Azure file or an NFS share.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: wordpress-pv-volume
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/home/ubuntu/project/wp-data"
 ```   
It defines **storageClassName: manual** for the PersistentVolume, which will be used to bind PersistentVolumeClaim requests to this PersistentVolume.

The Persistent Volume Claim for Wordpress is shown below:
 ```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: wordpress-pv-claim
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 4Gi
```
A PVC will bind to a persistent volume if it matches the **AccessMode** and **storageClassName** that we defined in the file. In our specific case, the Access Mode is **ReadWriteOnce** and the **storageClassName** is **manual**.
The configuration specifies a size of 4Gi and an access mode of **ReadWriteOnce**, which means the volume can be mounted as read-write by a single Node.


<br>
In a Kubernetes cluster, Services act as an abstraction layer, enabling communication between different parts of an application.
Kubernetes Service DNS is a mechanism that assigns DNS names to these Services, making it easier for applications to discover and communicate with each other dynamically.
When a Service is created within a Kubernetes cluster, a DNS record is automatically assigned to it. This DNS record is accessible within the cluster, allowing other components to resolve the Service’s IP address using its DNS name. <br>
Suppose we have a Kubernetes Service named “mysql-service” that exposes an application. Kubernetes will automatically assign a DNS record to this Service. The DNS name would typically be in the format: 

```Console
<service-name>.<namespace>.svc.cluster.local 
```

For our case, **"mysql-service.default.svc.cluster.local"** 
<br>
WordPress interacts with MySQL databases in Kubernetes through the Dynamic Service Discovery: Services can be discovered dynamically using their DNS names, enabling applications to adapt to changes in the cluster.


To apply the configurations WordPress, run the following commands:
```Console
kubectl apply -f wordpress-pv.yaml
kubectl apply -f wordpress-deployment.yaml
```

### <a name="Access to WordPress site"></a>6. Access to WordPress site
To access to WordPress site, obtain the external IP address of the WordPress Service with the following command:
```Console
kubectl get svc wordpress
```
As specified in the service the NodePort 32406, the WordPress is reachable on your IP address and port. <br>
Once you have the external IP address, you can access your WordPress site by navigating to that IP address in your web browser:

[![1]][1]

Add your WordPress Information about the admin account:

[![2]][2]

When the initial WordPress setup is completed, the success message is shown:
[![3]][3]

WordPress Dashboard is accessible:
[![4]][4]

### <a name="Reference"></a>7. Reference

https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/


<!--Image References-->
[1]: ./media/01.png "WordPress initial screenshot"
[2]: ./media/02.png "Add WordPress admin account and password"
[3]: ./media/03.png "Successful completion of initial step"
[4]: ./media/04.png "WordPress Dashboard"



<!--Link References-->

`Tags: AKS` <br>
`date: 03-01-24`

