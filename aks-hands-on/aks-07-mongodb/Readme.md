
<properties
pageTitle= 'AKS: MongoDB hands-on'
description= "AKS: MongoDB hands-on"
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
   ms.date="11/12/2023"
   ms.author="fabferri" />

# AKS: MongoDB hands-on
The article delves into the deployment of MongoDB in AKS cluster.

### <a name="login in azure subscription"></a>1. File list

|  file name                | description                                     |
| ------------------------- | ----------------------------------------------- |
| **01-mongo-secret.yaml**  | manifest file to store the MySQL root password  |
| **02-mongo-pv.yaml**      | persist volume 20Gi and persistent volume claim. <br> The persist volume defines a volume mount for **/data/db**      |
| **03-mongo.yaml**         | define a service to access to MongoDB and deploy MongoDB |
| **aks.sh**                | bash script to create the AKS cluster            |

### <a name="Create the AKS cluster"></a>2. Create the AKS cluster
To create the AKS cluster, login in Azure and then run the bash script: **`aks.sh`**


### <a name="Secrets"></a>3. Secrets
A Secret is an object that contains a small amount of sensitive data such as a password, a token, or a key. 
The file **01-mongo-secret.yaml** contains the MongoDB administrator username and administrator password:

```yaml
apiVersion: v1
kind: Secret
metadata:
    name: mongodb-secret
type: Opaque
data:
    mongo-root-username: dXNlcm5hbWU=
    mongo-root-password: cGFzc3dvcmQ=
```
Kubernetes provides diffent type of Secrets; in the specific case discussed here **type: Opaque** <br>
The Secret resource contains the **data** field, used to store arbitrary data in format of dictionaly, with values base64 encoded. <br>

Convert the strings to base64 coding:
```bash
echo -n username | base64
dXNlcm5hbWU=


echo -n password | base64
cGFzc3dvcmQ=
```

Decode base64:
```bash
echo -n 'dXNlcm5hbWU=' | base64 -d
username

echo -n 'cGFzc3dvcmQ=' | base64 -d
password
```

```bash
kubectl apply -f mongo-secret.yaml
```


### <a name="PV and PVC"></a>4. Persistent Storage (PV) and Persistent Volume Claim (PVC)
PV and PVC are defined in **02-mongo-pv.yaml** <br>

List the StorageClasses in the cluster by running this command:

```console
kubectl get storageclass
NAME                    PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
azurefile               file.csi.azure.com   Delete          Immediate              true                   151m
azurefile-csi           file.csi.azure.com   Delete          Immediate              true                   151m
azurefile-csi-premium   file.csi.azure.com   Delete          Immediate              true                   151m
azurefile-premium       file.csi.azure.com   Delete          Immediate              true                   151m
default (default)       disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   151m
managed                 disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   151m
managed-csi             disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   151m
managed-csi-premium     disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   151m
managed-premium         disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   151m



kubectl get storageclass default 
NAME                PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
default (default)   disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   150m
```
The default StorageClass is marked by (default). <br>
More information about the default StorageClass:
```console
kubectl get storageclass default -o yaml

allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  creationTimestamp: "2024-01-07T14:22:32Z"
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
    kubernetes.io/cluster-service: "true"
  name: default
  resourceVersion: "484"
  uid: d5adea3a-086b-48cc-bc34-9c49a3cdd5c8
parameters:
  skuname: StandardSSD_LRS
provisioner: disk.csi.azure.com
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

- When a PVC does not specify a storageClassName, the default StorageClass is used.
- If you set the **storageclass.kubernetes.io/is-default-class** annotation to **true** on more than one StorageClass in your cluster, and you then create a PersistentVolumeClaim with no storageClassName set, Kubernetes uses the most recently created default StorageClass.
- Only one StorageClass can be set as the default. If more objects are marked as default, it is not possible to create a PersistentVolumeClaim without an explicitly specified storageClassName.
For more information about [default storageclass](https://kubernetes.io/docs/concepts/storage/storage-classes/#default-storageclass)
<br>

In the default StorageClass is possibile to filter only the value assigned to **storageclass.kubernetes.io/is-default-class**:
```bash
kubectl get storageclass default -o=jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}{"\n"}'
true
```

A PersistentVolumeClaim is an object that represents a request by a pod for a persistent storage volume.
A common problem is that storage backends are not globally accessible from all nodes in the cluster. In this case, PersistentVolumes might be provisioned without knowledge of the pod's scheduling requirements, resulting in unschedulable pods.
Cluster administrators can address issues like this by setting the volume binding mode to **WaitForFirstConsumer**. This mode delays the binding and provisioning of the PersistentVolume until the creation of a pod using a matching PersistentVolumeClaim.

<br>

After you create the PersistentVolumeClaim, the Kubernetes control plane looks for a PersistentVolume that satisfies the claim's requirements. If the control plane finds a suitable PersistentVolume with the same StorageClass, it binds the claim to the volume. <br>
For dynamically provisioned PersistentVolumes, the default reclaimPolicy field is "Delete". This means that a dynamically provisioned volume is automatically deleted when a user deletes the corresponding PersistentVolumeClaim. <br>

In our case the PersistentVolumeClaim is created without storageClassName set, than the default StorageClass is used that has a **provisioner: disk.csi.azure.com** and **reclaimPolicy: Delete** <br>

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mongodb-pv-volume
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/db"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pv-claim
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
```
The persistent volume defined in **mysql-pv.yaml** creates a volume using a **storageClassName: manual**. <br>
**storageClassName: manual** is an arbitrary name as it does not require CSI driver to provision volume. It's an arbitrary name that you can used in PV/PVC with local volumes. Local volumes do not support dynamic provisioning; however a StorageClass should still be created to delay volume binding until a Pod is actually scheduled to the appropriate node. This is specified by the <ins>WaitForFirstConsumer</ins> volume binding mode.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```


```bash
kubectl apply -f mongo-pv.yaml
```


### <a name="MongoDB"></a>5. Deployment of MongoDB

You can run a stateful application by creating a Kubernetes Deployment and connecting it to an existing PersistentVolume using a PersistentVolumeClaim. 
For example, **03-mongo.yaml** file describes a Deployment that runs MongoDB and references the PersistentVolumeClaim. The file defines a volume mount for **/data/db**, and then creates a PersistentVolumeClaim that looks for a 20Gi volume. This claim is satisfied by any existing volume that meets the requirements, or by a dynamic provisioner.

```bash
kubectl apply -f mongo.yaml
```
The MongoDB image is in hub.docker.com


kubectl get secret

### <a name="MongoDB"></a>6. Verification

After the deployment use the following command for verification:
```console
kubectl get pv
kubectl get pvc
kubectl get service
kubectl get pod -o wide
kubectl get pod --watch
kubectl describe pod <podName>
kubectl get all
```

Verifing that the pod is running:
```bash
kubectl get pods -o wide
```
The command shows the name of pod, it cna be used to connect to the container. <br>
Connect to the container:
```Console
kubectl exec <Pod_Name> -it -- /bin/bash
```

Inside the container run the command **mongosh**:
```console
root@mongodb-deployment-864486df67-lr9rm:/# mongosh
Current Mongosh Log ID: 659afa9bb47ae697352d905c
Connecting to:          mongodb://127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+2.1.1
Using MongoDB:          7.0.4
Using Mongosh:          2.1.1

For mongosh info see: https://docs.mongodb.com/mongodb-shell/


To help improve our products, anonymous usage data is collected and sent to MongoDB periodically (https://www.mongodb.com/legal/privacy-policy).
You can opt-out by running the disableTelemetry() command.

test>
```
We have few options to connect to the MongoDB. <br>
Running MongoDB shell without connecting to a database:
```Console
mongosh --nodb
```

Login without authentication: 
```console
mongosh "mongodb://localhost:27017"
```

Login with authentication:
```console
mongosh "mongodb://localhost:27017" --username username --authenticationDatabase admin
```

Once connected, you can check how many databases are present in your MongoDB deployment. Simply use the db command to list the available databases.
```
test> show dbs
admin   100.00 KiB
config   60.00 KiB
local    72.00 KiB


test> db
test
```

There is no "create" command in the MongoDB Shell. In order to create a database, you will first need to switch the context to a non-existing database using the use command:

```console
test> use mydb
switched to db mydb

mydb>
mydb> db.user.insert({ "_id" : 8752, "title" : "Divine Comedy", "author" : "Dante", "copies" : 1000 })

db.books.insertMany([
   { "_id" : 8752, title:  "Divine Comedy", "author" : "Dante", "copies" : 1000},
   { "_id" : 7020, "title" : "Iliad", "author" : "Homer", "copies" : 10 },
   { "_id" : 7000, "title" : "The Odyssey", "author" : "Homer", "copies" : 50 },
]);

mydb> db.books.find()
[
  { _id: 8752, title: 'Divine Comedy', author: 'Dante', copies: 1000 },
  { _id: 7020, title: 'Iliad', author: 'Homer', copies: 10 },
  { _id: 7000, title: 'The Odyssey', author: 'Homer', copies: 50 }
]

mydb> show dbs
admin   100.00 KiB
config  108.00 KiB
local    72.00 KiB
mydb     80.00 KiB


mydb> show collections
books
user

mydb> db.test.help()
```

### <a name="MongoDB"></a>7. Delete all the MongoDB deployment
```Console
kubectl delete -f .
```

### <a name="Base64"></a>8. ANNEX: Base64 encoding/deconding
Base64 encoding is a format designed to prevent communication “mishaps” during the transfer of binary information. It achieves this through the conversion of binary data and a “lookup table” — data is eventually made in a stream of ASCII characters, which can then be transmitted and decoded. 
- On base 64 encoded data, the resultant string is always larger than the original (i.e. this is not a compression algorithm). - base 64 does not encrypt any information — it uses a “standard” table of characters to encode and decode information. 
- using base 64 encoding is a reliable way to ensure that a transmission of binary information is never misinterpreted.