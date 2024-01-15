
<properties
pageTitle= 'AKS: deployment of PostgreSQL with kustomize'
description= "AKS: deployment of PostgreSQL with kustomize"
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
   ms.date="02/01/2024"
   ms.author="fabferri" />

# AKS: deployment of PostgreSQL with kustomize
This hands-on shows you how to deploy a **single-instance stateful application** in Kubernetes using a PersistentVolume (PV) and a deployment. The deployment uses kubectl commands on an existing Kubernetes cluster and deploys a PostgreSQL. <br>
The resources will be created in the order they appear in the YAML file. Therefore, it's best to specify the service first, since that will ensure the scheduler can spread the pods associated with the service as they are created by the controller(s), such as Deployment.
The PostgreSQL deployment can be done running multiple `kubectl apply` commands in sequence with manifest files. There is a more structured way to run the deployment through  **kustomize**, a software configuration management tool. The hands-on discuss about the deployment created by **kustomize**.

### <a name="File List"></a>1. File List

|  file name                     | description                                     |
| ------------------------------ | ----------------------------------------------- |
| **aks.sh**                     | bash script to create the AKS cluster           |
| **./base/postgre-secret.yaml** | The YAML file specifies the password for PostgreSQL administrator. The Secret **type: Opaque** required encode base64 values. <br> The secret file contains the admin password for PostgreSQL |
| **./base/postgre-pv.yaml**     | The YAML file defines a volume mount for ***/var/lib/postgresql/data**, and then creates a PersistentVolumeClaim that looks for a 20Gi volume. This claim is satisfied by any existing volume that meets the requirements. |
| **/base/postgre.yaml**         | The YAML file describes a Deployment that runs PostgrSQL and references the PersistentVolumeClaim. |
| **./base/kustomization.yaml**  | it is the base kustomization file |



The **postgre.yaml** manifest file reference the image in docker hub: https://hub.docker.com/_/postgres
As shown in the docker hub documentation, PostgreSQL has the following environment variables:

[![1]][1]

The **postgre-secret.yaml** specifies the password for the **postgres** user. The Secret **type: Opaque** requires base64 encoding of secrets. <br>
The encoding and deconding based64 the administrator password for PostgreSQL is shown below:

```bash
echo -n 'MyAdminPassword01' | base64
TXlBZG1pblBhc3N3b3JkMDE=

echo TXlBZG1pblBhc3N3b3JkMDE= | base64 --decode 
```

### <a name="Kustomize"></a>2. Kustomize
Kustomize is an open-source standalone configuration management tool for Kubernetes to customize Kubernetes objects through a kustomization file. <br>
It allows you to define and manage Kubernetes objects such as Deployments, Daemonsets, Services, configMaps, etc. for multiple environments in a declarative manner without modifying the original YAML files. <br>
Kustomize supports composition of different resources. The resources field, in the **kustomization.yaml** file, defines the list of resources to include in a configuration.
Kustomize has two key concepts, **base** and **overlays**. 
- A **base** is a directory with a kustomization.yaml, which contains a set of resources and associated customization. A **base** could be either a local directory or a directory from a remote repo.
- An **overlay** is a directory with a **kustomization.yaml** that refers to other kustomization directories as its bases

A **base** has no knowledge of an **overlay** and can be used in multiple overlays. An **overlay** may have multiple **bases** and it composes all resources from bases and may also have customization on top of them.

The **kustomization.yaml** file is the main file used by the Kustomize tool. <br>
When you execute Kustomize, it looks for the file named **kustomization.yaml**. This file contains a list of all of the Kubernetes resources (YAML files) that should be managed by Kustomize. It also contains all the customizations that we want to apply to generate the customized manifest. 

In this hands-on only the **base** is considered. <br>
Kustomize module is available as a standalone binary or as built into kubectl. 
```console
kubectl kustomize --help
```

All the manifest files are in the same **./base** directory :
```console
base
├── kustomization.yaml 
├── postgre-pv.yaml
├── postgre-secret.yaml
└── postgre.yaml
```


In Kustomize there is the concept of Transformers. Kustomize has several built-in transformers. Let’s see some common transformers:
* **commonLabel** – It adds a label to all Kubernetes resources
* **namePrefix** – It adds a common prefix to all resource names
* **nameSuffix** – It adds a common suffix to all resource names
* **Namespace** – It adds a common namespace to all resources
* **commonAnnotations** – It adds an annotation to all resources



The **kustomization.yaml** reference in sequence all the manifest files required to create the full deployment:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- postgre-secret.yaml
- postgre-pv.yaml
- postgre.yaml
namePrefix: dev-
```

### <a name="apply kustomize config"></a>3. Apply the kustomize configuration

To apply the base kustomize configuration: `kubectl apply --kustomize='<kustomization_directory>'` 
```console
kubectl apply --kustomize='./base'
```


### <a name="Verification"></a>4. Verification
To view all the objects at once:
```
kubectl get all
```

Get the name of the pod:
```Console
kubectl get pod
```

By pod name login in the container:
```
kubectl exec --stdin --tty <PodName> -- /bin/bash 
kubectl exec -i -t <PodName>  -- /bin/bash
```

Inside the container, connect to PostgreSQL:
```Console
psql -h localhost -p 5432 -U postgres -W
```
The command prompt for **postgres** password: this is the password specified in **postgre-secret.yaml** manifest file.
When login inside the PostgreSQL the prompt appears: **postgres=#**  <br>
Run the following PostGreSQL commands:
```SQL
select version();
CREATE DATABASE db1;
CREATE USER user1 WITH ENCRYPTED PASSWORD 'user1password';
GRANT ALL PRIVILEGES ON DATABASE db1 TO user1;
-- lists all the users
\du
-- check the available database list
\l
-- connect/select a desired database;
\c db1;
-- create a table
CREATE TABLE COMPANY(
   ID INT PRIMARY KEY     NOT NULL,
   NAME           TEXT    NOT NULL,
   AGE            INT     NOT NULL,
   ADDRESS        CHAR(50),
   SALARY         REAL
);

-- verify if your table has been created successfully 
\d

INSERT INTO COMPANY (ID,NAME,AGE,ADDRESS,SALARY) VALUES (1, 'Sean', 24, 'Oregon', 30000.00);
SELECT * FROM COMPANY;
DELETE FROM COMPANY WHERE ID = 1;
```

### <a name="Verification"></a>5. Delete all deployment

```
kubectl delete --kustomize='./base'
```

### <a name="NOTE"></a>6. NOTE
To perform resources creation in bulk utilization of kustomize can be avoid calling kubectl apply with multiple files:
```Console
kubectl apply \
     -f ./base/postgre-secret.yaml \
     -f ./base/postgre-pv.yaml \
     -f ./base/postgre.yaml
``` 

To delete all:
```Console
kubectl delete \
     -f ./base/postgre.yaml \
     -f ./base/postgre-pv.yaml \
     -f ./base/postgre-secret.yaml
``` 


### <a name="reference"></a>7. Reference
https://kubectl.docs.kubernetes.io/  <br>
https://kustomize.io/


<!--Image References-->
[1]: ./media/postgresql-doc.png "postgresql: Environment Variables"


`Tags: AKS` <br>
`date: 02-12-23`

