
<properties
pageTitle= 'Kubernetes overview'
description= "AKS hand-on episode 1: overview"
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

# Kubernetes architecture
Kubernetes is an open-source orchestration platform. It automates the deployment, scaling and management of containerized applications.
Kubernetes cluster use a set of hosts/VMs named Nodes that are used to run containerized applications.

[![1]][1]

There are two core pieces in Kubernetes cluster: 
- **control plane**: it is responsible to manage the state of the cluster
- **worker nodes**: it is a set of nodes run the containerized workloads

[![2]][2]

Pods are managed by Kubernetes control plane:

[![3]][3]

The **API server** is the primary interface between the control plane and the rest of the cluster.
it exposes the RESTful API that allows clients to interact with control plane. <br>

**ectd** is distributed key-value store. it stores the cluster's persistent state. it is used by APIserver and other components of the control plane to store and retrieve information about the cluster.

[![4]][4]

The core components of Kubernetes that run on the worker nodes include kubelet, container runtime and kube-proxy:

[![5]][5]

- **kubelet** is daemon that runs on each worker node. It is responsible for communication with the control plane. it receives instruction from the control plane about which pods to run on the node, and ensure that the desired state of the pods is maintained. <br>
- the **container runtime** runs the containers on the worker nodes. it is responsible for pulling the container images from the registry, starting and stopping the container and managing the container's resources.
- **kube-proxy** is a network proxy that runs on each worker node. it is resposabile for routing traffic to the correct pods. it also provides load balancing for the pods and ensure that traffic is distributed across the pods.




### <a name="Kubernetes objects"></a> Kubernetes objects

Kubernetes objects are persistent entities in the Kubernetes system. A Kubernetes object is a "<ins>record of intent</ins>"--once you create the object, the Kubernetes system will constantly work to ensure that object exists. <br>
By creating objects, you're effectively telling the Kubernetes system what is your cluster's desired state. In Kubernetes the YAML manifest file defines the desire state. <br>

Basic objects include:
- **Pod**. Pods are the smallest deployable units of computing that you can create and manage in Kubernetes. A pod is group of one or more containers. Kubernetes uses pods to run an instance of your application. A pod is a logical resource, but application workloads run on the containers. Pods are typically ephemeral, disposable resources. Pods in a Kubernetes cluster are used in two main ways:
   - **Pods that run a single container**. The "one-container-per-Pod" model is the most common Kubernetes use case; in this case, you can think of a Pod as a wrapper around a single container. Kubernetes manages Pods rather than managing the containers directly.
   - **Pods that run multiple containers** that need to work together. A Pod can encapsulate an application composed of multiple co-located containers. Pods provides shared storage and networking for those containers.
- **Service**. it is a method for exposing a network application that is running as one or more Pods.
- **Volume**. An abstraction that lets us persist data. (This is necessary because containers are ephemeral—meaning data is deleted when the container is deleted.)
- **Namespace**. Namespaces provides a mechanism for isolating groups of resources within a single cluster. Names of resources need to be unique within a namespace, but not across namespaces. Namespace-based scoping is applicable only for namespaced objects. Namespaces are a way to divide cluster resources between multiple users (via resource quota).





<!--Image References-->
[1]: ./media/01.png "high level architecture based on control plane and worker nodes"
[2]: ./media/02.png "control plane and worker nodes"
[3]: ./media/03.png "containers running in the pods"
[4]: ./media/04.png "etcd"
[5]: ./media/05.png "components in the worker nodes"

<!--Link References-->



`Tags: AKS` <br>
`date: 11-12-23`

