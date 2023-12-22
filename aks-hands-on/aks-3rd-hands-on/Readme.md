
<properties
pageTitle= 'AKS: 3rd hands-on'
description= "AKS: 3rd hands-on"
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

# Azure Kubernetes Service (AKS): 3rd hands-on

### <a name="login in azure subscription"></a> STEP 1: Login in the Azure subscription and create the Kubernetes cluster
The following setup has been done in Windows host with Azure CLI installed locally.

- `az login --use-device-code` - login with the device authentication code in the web browser
- `az account list --output table`  - Get a list of available subscriptions <br>
- `az account show`                 - Show the subscription you are currently using <br>
- `az account show --output table`  - Show the subscription you are currently using by tabular format <br>
- `az account list --query "[?isDefault]" ` - Get the current default subscription <br>
- `az account set --subscription "AzureDemo"` - Change the active subscription using the subscription name 
- `az account list --query "[?name=='AzureDemo'].id" --output tsv` - Get the Azure subscription ID
- `$SubId="$(az account list --query "[?name=='AzureDemo'].id" --output tsv)"; az account set --subscription $SubId`  - Change the active subscription (powershell)
- `az aks install-cli` - (<ins>optional</ins>) - One time operation if you do not have aks command installed 
- `az aks create -g $rg -n $clusterName --enable-managed-identity --node-count 3 --ssh-key-value $SSH` - Create the Kubernetes cluster with 3 nodes.
- `az aks get-credentials --resource-group $rg --name $clusterName` - Configure kubectl to connect to the Kubernetes cluster

The powershell script **01-az-k8s-deployment.ps1** create the resource group, the Kubernetes cluster and the credential to connect to the Kubernetes cluster. 

After cluster creation: 
- `az aks list -o table`  - List the properties of Kubernetes cluster: name, Azure region, Resource Group, Kubernetes Version, etc.
- `kubectl get nodes -o wide` - List of the nodes in Kubernetes cluster 

<br>

> [!NOTE]
> - `kubectl config view` - View the config file
> - `kubectl config get-contexts` - Get all contexts in the file ~\.kube\config
> - `kubectl config current-context` - Find the current context
> - `kubectl config use-context <CONTEXT_NAME>` - Switch between contexts
> - `kubectl config delete-context <CLUSTER_NAME>` - Delete a context



### <a name="deploy the application"></a>STEP 2: Check nodes, pods and services
To retrieve the pods scheduled on each node in a Kubernetes cluster, you can use the `kubectl get pods --all-namespaces -o wide`
Without specification of namespace the default namespace is selected:
`kubectl get pods --namespace default -o wide` and  `kubectl get pods -o wide` gives the same output.

```console
kubectl get nodes -o wide    
NAME                                STATUS   ROLES   AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
aks-nodepool1-30717371-vmss000000   Ready    agent   2m9s    v1.27.7   10.224.0.4    <none>        Ubuntu 22.04.3 LTS   5.15.0-1052-azure   containerd://1.7.5-1       
aks-nodepool1-30717371-vmss000001   Ready    agent   2m14s   v1.27.7   10.224.0.5    <none>        Ubuntu 22.04.3 LTS   5.15.0-1052-azure   containerd://1.7.5-1       


kubectl get pods -o wide
NAME                                READY   STATUS    RESTARTS   AGE   IP            NODE                                NOMINATED NODE   READINESS GATES
nginx-deployment-76d9685c48-8mgdj   1/1     Running   0          21s   10.244.0.13   aks-nodepool1-30717371-vmss000001   <none>           <none>
nginx-deployment-76d9685c48-b59vt   1/1     Running   0          21s   10.244.0.11   aks-nodepool1-30717371-vmss000001   <none>           <none>
nginx-deployment-76d9685c48-csjtm   1/1     Running   0          21s   10.244.0.12   aks-nodepool1-30717371-vmss000001   <none>           <none>

kubectl get service
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
kubernetes   ClusterIP      10.0.0.1       <none>          443/TCP        4m50s
nginx        LoadBalancer   10.0.253.130   20.49.255.185   80:30036/TCP   2m10s

kubectl get pods --show-labels
NAME                                READY   STATUS    RESTARTS   AGE    LABELS
nginx-deployment-76d9685c48-8mgdj   1/1     Running   0          3h4m   app=nginx,pod-template-hash=76d9685c48
nginx-deployment-76d9685c48-b59vt   1/1     Running   0          3h4m   app=nginx,pod-template-hash=76d9685c48
nginx-deployment-76d9685c48-csjtm   1/1     Running   0          3h4m   app=nginx,pod-template-hash=76d9685c48

```

### <a name="Kubernetes Limits and Requests"></a>STEP 3: Kubernetes Limits and Requests

When a Pod is created, the Kubernetes scheduler selects a node for the Pod to run on. Each node has a maximum capacity for each of the resource types: the amount of CPU and memory it can provide for Pods. The scheduler ensures that, for each resource type, the sum of the resource requests of the scheduled containers is less than the capacity of the node. Note that although actual memory or CPU resource usage on nodes is very low, the scheduler will refuse to place a Pod on a node if the capacity check fails.<br>
When you specify a Pod, you can **optionally** specify how much of each resource a container needs. The most common resources to specify are CPU and memory (RAM).
- When you specify the resource request for containers in a Pod, the kube-scheduler uses this information to decide which node to place the Pod on. 
- When you specify a resource limit for a container, the kubelet enforces those limits so that the running container is not allowed to use more of that resource than the limit you set. The kubelet also reserves at least the request amount of that system resource specifically for that container to use.
<br> <br>

When defining resources for a container in Kubernetes, there are two values that can be specified: **limits** and **requests**.
- Kubernetes defines Limits as the <ins>maximum amount of a resource to be used by a container</ins>. This means that the container can <ins>never consume more than the memory amount or CPU amount indicated</ins>. Limits are used:
   - When allocating Pods to a Node. If no requests are set, by default, Kubernetes will assign requests = limits.
   - At runtime, Kubernetes will check that the containers in the Pod are not consuming a higher amount of resources than indicated in the limit.
- Requests, on the other hand, are the <ins>minimum guaranteed amount of a resource that is reserved for a container</ins>.



> [!Note] <br>
> If the node where a Pod is running has enough of a resource available, it's possible (and allowed) for a container to use more resource than its request for that resource specifies. However, **a container is not allowed to use more than its resource limit**.

- CPU represents computing processing time. 
- The CPU resource is measured in CPU units. One CPU unit, in Kubernetes, is equivalent to 1 physical CPU core, or 1 virtual core (in AKS 1 Azure vCore).
- You can use millicores (m) to represent smaller amounts than a core (e.g., 500m would be half a core). The minimum amount is 1m. 
- For example 500m CPU, 500 milliCPU, and 0.5 CPU are all the same.
- A Node might have more than one core available, so requesting CPU > 1 is possible. 
- CPU is a compressible resource, meaning that it can be stretched to satisfy all the demand. This means that its usage can be throttled, which leads to increased application latency but does not cause pod evictions.

<br>
- Memory is measured in Kubernetes in bytes
- You can use, E, P, T, G, M, k to represent Exabyte, Petabyte, Terabyte, Gigabyte, Megabyte and kilobyte, although only the last four are commonly used.
- You can define Mebibytes using **Mi**, as well as Ei, Pi, Ti. A Mebibyte is 2 to the power of 20 bytes. 


On Linux, the container runtime typically configures kernel **cgroups** that apply and enforce the limits you defined. <br>
Control Groups, or **cgroups** for short, are a Linux kernel feature that takes care of resource allocation (CPU time, memory, network bandwidth, I/O), prioritization and accounting. **cgroups** are also a building block of containers, so without cgroups there would be no containers. The cgroups are groups, so they group processes in parent-child hierarchy, which forms a tree. For example - parent cgroup is assigned 128Mi of RAM, then sum of RAM usage of all of its children cannot exceed 128Mi. This hierarchy lives in **/sys/fs/cgroup/**, which is the cgroup filesystem (cgroupfs)

- The CPU limit defines a hard ceiling on how much CPU time a container can use. During each scheduling interval (time slice), the Linux kernel checks to see if this limit is exceeded; if so, the kernel waits before allowing that **cgroup** to resume execution. 
- The CPU request typically defines a weighting. If several different containers (cgroups) want to run on a contended system, workloads with larger CPU requests are allocated more CPU time than workloads with small requests.

The sum of the CPU requests for all containers scheduled on a node will never exceed the capacity of the node. Once they are scheduled, they may get additional CPU time, depending on other containers’ CPU usage on the same node.
CPU limits enforce a limit on the amount of CPU time a container can use in any specific time slice, regardless of whether the node has spare cycles. This is enforced by the configuration values for CFS quota and period for any container that has specified a CPU limit:

- Quota: CPU time available for a CPU time period (in microseconds). 
- Period: time period to refill the cgroup quota (by default, 100,000 microseconds, or 100 ms). 
These values are defined for cgroup v2 in: **/sys/fs/cgroup/cpu/cpu.max** <br>
The first value is the allowed time quota in microseconds for which all processes collectively in a child group can run during one period. The second value specifies the length of the period.

<br>
<br>


Let’s say we have a single node with 1 CPU core and three pods (each of which have one container and one thread) that are requesting 200, 400, and 200 millicores (m) of CPU, respectively. The scheduler can place them all on the node because the sum of requests is less than 1 CPU core: <br>

POD1: .requests:cpu: 200m, POD2: .requests:cpu: 400m, POD3: .requests:cpu: 200m 

[![1]][1]


For any time slice of 100 ms, 
- POD 1 is guaranteed to have 20 ms of CPU time, 
- POD 2 is guaranteed to have 40 ms of CPU time, 
- POD 3 is guaranteed to have 20 ms of CPU time.

But if the pods are not using these CPU cycles, these numbers don’t have any effect: any pod scheduled on the node could use them. For example, in a time slice of 100 ms, this scenario is possible:

[![2]][2]

In the example above, POD 1 is idle, and PODs 2 and 3 are able to use more CPU time than what was guaranteed to them because the node still had spare CPU cycles.<br>
But when there is contention, CFS uses CPU requests to allocate CPU shares proportionally to requests.
Continuing with our example, let’s say that in the next period of 100 ms, the three pods need more CPU than the node’s CPU availability. In each time slice of 100 ms, CPU cycles will be divided in a 1:2:1 proportion (because POD 1-requested 200m; POD 2 400m; and POD 3 200m):

[![3]][3]

a CPU request will guarantee minimum CPU time per cycle to each container. But in cases of contention, pods may or may not be able to use more CPU than requested, depending on the CPU requests and needs of the other pods that are scheduled on the same node.
<br> <br>

Let’s see how CPU limits will affect our previous example. Our three pods (with one container and one thread each) have set the following CPU requests and limits:

[![4]][4]

POD 1 is idle, while POD 2 and POD 3 need more CPU. 
Now that we’ve specified CPU limits for all three pods, PODs 2 and 3 will be throttled even if they have more CPU needs in this specific period—and even if the node has enough available CPU to fulfil those needs. POD 2 will only be allowed to use 40 ms and POD 3 20 ms in a 100-ms period:

[![5]][5]



### <a name="Kubernetes Limits and Requests"></a>STEP 4:Specify a CPU request that is too big for the Nodes
The manifest file **cpu-request-limit.yaml** create a Pod that has a CPU request so big that it exceeds the capacity of any Node in the cluster. <br>
The configuration file for a Pod that has one Container. The Container requests 100 CPU, which exceed the capacity of any Node in the cluster.

```Console
kubectl create namespace cpu-example
kubectl apply -f cpu-request-limit.yaml --namespace=cpu-example
NAME       READY   STATUS    RESTARTS   AGE
cpu-demo   0/1     Pending   0          9s
```

View the Pod status:
```bash
kubectl get pod cpu-demo --namespace=cpu-example
```

The output shows that the Pod has not been scheduled to run on any Node, and it will remain in the Pending state indefinitely. <br>
View detailed information about the Pod, including events:
```
kubectl describe pod cpu-demo --namespace=cpu-example
Name:             cpu-demo
Namespace:        cpu-example
Priority:         0
.....
.....
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  40s   default-scheduler  0/2 nodes are available: 2 Insufficient cpu. preemption: 0/2 nodes are available: 2 No preemption victims found for incoming pod..
```
The output shows that the Container cannot be scheduled because of insufficient CPU resources on the Nodes.
<br>
Delete the pod and namespace: 

```bash
kubectl delete pod cpu-demo --namespace=cpu-example
kubectl delete namespace cpu-example
```




### <a name="Kubernetes Limits and Requests"></a>STEP 5: Apply the manifest file nginx-resource-limit.yaml
```bash
kubectl apply -f nginx-resource-limit.yaml
```

Description of manifest file
**spec.containers.resources** specifies:
```yaml
        resources:
          limits:
            cpu: 500m       # each container should not be allowed to consume more than 0.6 CPU.
            memory: 200Mi   # each container should not be allowed to consume more than 200Mi of memory.
          requests:
            cpu: 100m       # each container requires 100m of CPU resources
            memory: 200Mi   # each container requires 200Mi of memory on the node
```

```console
kubectl get node -o wide
NAME                                STATUS   ROLES   AGE    VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
aks-nodepool1-35689902-vmss000000   Ready    agent   100m   v1.27.7   10.224.0.4    <none>        Ubuntu 22.04.3 LTS   5.15.0-1052-azure   containerd://1.7.5-1
aks-nodepool1-35689902-vmss000001   Ready    agent   100m   v1.27.7   10.224.0.5    <none>        Ubuntu 22.04.3 LTS   5.15.0-1052-azure   containerd://1.7.5-1

kubectl get pod -o wide
NAME                                READY   STATUS    RESTARTS   AGE   IP            NODE                                NOMINATED NODE   READINESS GATES
nginx-deployment-7655f6b7cd-pjjgh   1/1     Running   0          13s   10.244.0.12   aks-nodepool1-35689902-vmss000000   <none>           <none>
nginx-deployment-7655f6b7cd-sxztk   1/1     Running   0          13s   10.244.1.3    aks-nodepool1-35689902-vmss000001   <none>           <none>
nginx-deployment-7655f6b7cd-z9qhk   1/1     Running   0          13s   10.244.1.4    aks-nodepool1-35689902-vmss000001   <none>           <none>

kubectl get service
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)        AGE
kubernetes   ClusterIP      10.0.0.1       <none>          443/TCP        103m
nginx        LoadBalancer   10.0.149.207   20.49.163.187   80:30036/TCP   3m1s
```

Connect to the pod and check the value of :
```
kubectl exec nginx-deployment-7655f6b7cd-pjjgh --stdin --tty  -- /bin/bash

root@nginx-deployment-7655f6b7cd-pjjgh:/# cat /sys/fs/cgroup/cpu.max
50000 100000
```
**50000**: the first value is the allowed time quota in microseconds for which all processes collectively in a child group can run during one period. 
**100000**: The second value specifies the length of the period in microseconds (in this case 100 ms)

## <a name="Kubernetes liveness probes"></a>STEP 6: Liveness probes
Many applications running for long periods of time eventually transition to broken states, and cannot recover except by being restarted. Kubernetes provides liveness probes to detect and remedy such situations. <br>

In the manifest **nginx-resource-limit.yaml**
```yaml
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

- `periodSeconds`: it specifies that the kubelet should perform a liveness probe every 5 seconds. <br>
- `initialDelaySeconds`: it tells to the kubelet that it should wait 5 seconds before performing the first probe. 
To perform a probe, the kubelet executes the command HTTP GET to the server that is running in the target container and listening on port 880. If the command succeeds, it returns 0, and the kubelet considers the container to be alive and healthy. If the command returns a non-zero value, the kubelet kills the container and restarts it. <br>
Any code greater than or equal to 200 and less than 400 indicates success. Any other code indicates failure.

### <a name="Kubernetes liveness probes"></a>STEP 7: ConfigMaps
A **ConfigMap** is a dictionary of configuration settings. This dictionary consists of key-value pairs of strings. Kubernetes provides these values to the containers. Like with other dictionaries the key lets you get and set the configuration value. <br>
Use a **ConfigMap** allows to keep your application code separate from your configuration.
<br> <br>

**ConfigMaps can be mounted as data volumes**. ConfigMaps can also be used by other parts of the system, without being directly exposed to the Pod. For example, ConfigMaps can hold data that other parts of the system should use for configuration.
To consume a ConfigMap in a volume in a Pod:
1. Create a ConfigMap or use an existing one. Multiple Pods can reference the same ConfigMap.
2. Modify your Pod definition to add a volume under **.spec.volumes[]**. Name the volume anything, and have a **.spec.volumes[].configMap.name** field set to reference your ConfigMap object.
3. Add a **.spec.containers[].volumeMounts[]** to each container that needs the ConfigMap. Specify **.spec.containers[].volumeMounts[].readOnly = true** and **.spec.containers[].volumeMounts[].mountPath** to an unused directory name where you would like the ConfigMap to appear.
4. Modify your image or command line so that the program looks for files in that directory. Each key in the ConfigMap data map becomes the filename under mountPath.

The ConfigMap specifis in **data** the file index.html and its content:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: index-html-configmap
data:
  index.html: |
    <html>
    <h1>Welcome</h1>
    </br>
    <h1>Hi! This is a configmap Index file </h1>
    </html>

.....
.....
    spec:
      containers:
      volumes:
      - name: nginx-index-file
        configMap:
          name: index-html-configmap
```

A ConfigMap is created and added to the Kubernetes cluster:

[![6]][6]

Containers in the Pod reference the ConfigMap:

[![7]][7]

### <a name="delete the Kubernetes cluster"></a>STEP 8: Delete the Kubernetes cluster

Delete all the cluster objects created: <br>

`kubectl delete -f .\nginx-resource-limit.yaml`


<br> <br>

`Tags: aks` <br>
`date: 19-12-23`

<!--Image References-->
[1]: ./media/01.png "PODs with CPU requests"
[2]: ./media/02.png "PODs CPU allocation in 100ms slice"
[3]: ./media/03.png "PODs CPU allocation in 100ms slice"
[4]: ./media/04.png "configuration with CPU request and CPU limit in the PODs"
[5]: ./media/05.png "PODs trottleling in CPU due th presence of CPU limits"
[6]: ./media/06.png "A ConfigMap is created and added to the cluster"
[7]: ./media/07.png "Containers in the Pod reference the ConfigMap"

<!--Link References-->