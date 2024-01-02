
<properties
pageTitle= 'Kubernetes: imperative commands'
description= "Kubernetes: edit yaml with vim"
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

# kubectl commands output

### <a name="Create a pod with imperative command"></a> Create a pod with kubectl run

```Console
$ kubectl run nginx --image=nginx

$ kubectl get pods
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          7s
```

```
$ kubectl get pod -o yaml
apiVersion: v1
items:
- apiVersion: v1
  kind: Pod
  metadata:
    creationTimestamp: "2024-01-02T12:58:15Z"
    labels:
      run: nginx
    name: nginx
    namespace: default
    resourceVersion: "49599"
    uid: be38e147-830e-4e1a-bc0b-0a10d06b1028
  spec:
    containers:
    - image: nginx
      imagePullPolicy: Always
      name: nginx
      resources: {}
      terminationMessagePath: /dev/termination-log
      terminationMessagePolicy: File
      volumeMounts:
      - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
        name: kube-api-access-7g495
        readOnly: true
    dnsPolicy: ClusterFirst
    enableServiceLinks: true
    nodeName: aks-nodepool1-18823728-vmss000000
    preemptionPolicy: PreemptLowerPriority
    priority: 0
    restartPolicy: Always
    schedulerName: default-scheduler
    securityContext: {}
    serviceAccount: default
    serviceAccountName: default
    terminationGracePeriodSeconds: 30
    tolerations:
    - effect: NoExecute
      key: node.kubernetes.io/not-ready
      operator: Exists
      tolerationSeconds: 300
    - effect: NoExecute
      key: node.kubernetes.io/unreachable
      operator: Exists
      tolerationSeconds: 300
    volumes:
    - name: kube-api-access-7g495
      projected:
        defaultMode: 420
        sources:
        - serviceAccountToken:
            expirationSeconds: 3607
            path: token
        - configMap:
            items:
            - key: ca.crt
              path: ca.crt
            name: kube-root-ca.crt
        - downwardAPI:
            items:
            - fieldRef:
                apiVersion: v1
                fieldPath: metadata.namespace
              path: namespace
  status:
    conditions:
    - lastProbeTime: null
      lastTransitionTime: "2024-01-02T12:58:15Z"
      status: "True"
      type: Initialized
    - lastProbeTime: null
      lastTransitionTime: "2024-01-02T12:58:18Z"
      status: "True"
      type: Ready
    - lastProbeTime: null
      lastTransitionTime: "2024-01-02T12:58:18Z"
      status: "True"
      type: ContainersReady
    - lastProbeTime: null
      lastTransitionTime: "2024-01-02T12:58:15Z"
      status: "True"
      type: PodScheduled
    containerStatuses:
    - containerID: containerd://3d10396ff4e5a620632560bee36c2bc8e589d64a4af88c846cc2fb2c41de9802
      image: docker.io/library/nginx:latest
      imageID: docker.io/library/nginx@sha256:2bdc49f2f8ae8d8dc50ed00f2ee56d00385c6f8bc8a8b320d0a294d9e3b49026
      lastState: {}
      name: nginx
      ready: true
      restartCount: 0
      started: true
      state:
        running:
          startedAt: "2024-01-02T12:58:17Z"
    hostIP: 10.224.0.4
    phase: Running
    podIP: 10.244.0.14
    podIPs:
    - ip: 10.244.0.14
    qosClass: BestEffort
    startTime: "2024-01-02T12:58:15Z"
kind: List
metadata:
  resourceVersion: ""
```

### <a name="Create a pod yaml file"></a>  Create a pod yaml file without actually creating the pod
On day-to-day operations in Kubernetes, it is frequent utilization of the **kubectl flag --dry-run=client** to generate definitions of objects in yaml. By pairing it with **-o yaml**, you can printout the yaml file on the terminal:
```bash
$ kubectl run nginx --image=nginx --dry-run=client -o yaml
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

### <a name="Create a pod with imperative command"></a> Check the option avaiable with "kubectl create"

```console
$ kubectl create --help
....
Available Commands:
  clusterrole           Create a cluster role
  clusterrolebinding    Create a cluster role binding for a particular cluster role
  configmap             Create a config map from a local file, directory or literal value
  cronjob               Create a cron job with the specified name
  deployment            Create a deployment with the specified name
  ingress               Create an ingress with the specified name
  job                   Create a job with the specified name
  namespace             Create a namespace with the specified name
  poddisruptionbudget   Create a pod disruption budget with the specified name
  priorityclass         Create a priority class with the specified name
  quota                 Create a quota with the specified name
  role                  Create a role with single rule
  rolebinding           Create a role binding for a particular role or cluster role
  secret                Create a secret using a specified subcommand
  service               Create a service using a specified subcommand
  serviceaccount        Create a service account with the specified name
  token                 Request a service account token
...

```



### <a name="Create a deployment"></a>  Create a deployment

```Console
$ kubectl create deployment --image=nginx nginx
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   1/1     1            1           14s
```

### <a name="Create a manifes file for a deployment"></a> Create a deployment yaml file  without actually creating the deployment

```bash
$ kubectl create deployment --image=nginx nginx --dry-run=client -o yaml
```

The yaml file output is generated and shown to terminal: 
```
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: nginx
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
        resources: {}
status: {}
```

### <a name="Create a a deployment"></a>  Create a deployment

```Console
$ kubectl create deploy my-deploy --image=nginx --replicas=1
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   1/1     1            1           14s


$ kubectl get deploy
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
my-deploy   1/1     1            1           50s


$ kubectl get pod
NAME                        READY   STATUS    RESTARTS   AGE
my-deploy-bf798779c-k285d   1/1     Running   0          108s
nginx                       1/1     Running   0          71m
```

### <a name="Create a a deployment"></a> Modify an image of a deployment by "kubectl set"

```Console
$ kubectl set image deploy my-deploy *=nginx:1.19

deployment.apps/my-deploy image updated
```

Check:
```
$ kubectl get pod
NAME                         READY   STATUS    RESTARTS   AGE
my-deploy-848fbf5844-8d7kh   1/1     Running   0          49s
nginx                        1/1     Running   0          90m



$ kubectl describe pod my-deploy-848fbf5844-8d7kh 
Name:             my-deploy-848fbf5844-8d7kh
Namespace:        default
Priority:         0
Service Account:  default
Node:             aks-nodepool1-18823728-vmss000000/10.224.0.4
Start Time:       Tue, 02 Jan 2024 14:28:12 +0000
Labels:           app=my-deploy
                  pod-template-hash=848fbf5844
Annotations:      <none>
Status:           Running
IP:               10.244.0.16
IPs:
  IP:           10.244.0.16
Controlled By:  ReplicaSet/my-deploy-848fbf5844
Containers:
  nginx:
    Container ID:   containerd://1bf3e321ff9784a44f8b9e1330cae3ef4f458ca19873151e85af96dab743f641
    Image:          nginx:1.19
    Image ID:       docker.io/library/nginx@sha256:df13abe416e37eb3db4722840dd479b00ba193ac6606e7902331dcea50f4f1f2
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Tue, 02 Jan 2024 14:28:17 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-k8rkq (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  kube-api-access-k8rkq:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  4m20s  default-scheduler  Successfully assigned default/my-deploy-848fbf5844-8d7kh to aks-nodepool1-18823728-vmss000000
  Normal  Pulling    4m21s  kubelet            Pulling image "nginx:1.19"
  Normal  Pulled     4m16s  kubelet            Successfully pulled image "nginx:1.19" in 4.809848609s (4.809873509s including waiting)
  Normal  Created    4m16s  kubelet            Created container nginx
  Normal  Started    4m16s  kubelet            Started container nginx

```
Filtering the command output with grep:

```console
$ kubectl describe pod my-deploy-848fbf5844-8d7kh | grep -i image
    Image:          nginx:1.19
    Image ID:       docker.io/library/nginx@sha256:df13abe416e37eb3db4722840dd479b00ba193ac6606e7902331dcea50f4f1f2
  Normal  Pulling    7m48s  kubelet            Pulling image "nginx:1.19"
  Normal  Pulled     7m43s  kubelet            Successfully pulled image "nginx:1.19" in 4.809848609s (4.809873509s including waiting)
```

### <a name="scaling deployment"></a> Scaling out and shrink the deployment
Scaling the deployment from 1 to 2 replicas:
```Console
$ kubectl scale deploy my-deploy --replicas=2

$ kubectl get pod
NAME                         READY   STATUS    RESTARTS   AGE
my-deploy-848fbf5844-8d7kh   1/1     Running   0          14m
my-deploy-848fbf5844-m2n78   1/1     Running   0          80s
nginx                        1/1     Running   0          104m
```

### <a name="check the deployment  rollout"></a> Check deployment and annotation

Check if a deployment has been succesful rollout:
```console
$ kubectl rollout status deploy my-deploy
deployment "my-deploy" successfully rolled out
```

To display the history of rollout:

```Console
$ kubectl rollout history deploy my-deploy
deployment.apps/my-deploy 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

Note that in this case the CHANGE-CAUSE deployment revision is empty becasue it is not enabled the annotation. <br>

Update the image in the deployment:

```console
$ kubectl set image deploy my-deploy nginx=nginx:1.20
```

Annotate the deployment and create the history:

```Console
$ kubectl annotate deployment my-deploy kubernetes.io/change-cause="version change to 20.0 to latest" --overwrite=true

$ kubectl rollout history deploy my-deploy
deployment.apps/my-deploy 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         version change to 20.0 to latest
```

Change again the image version and check the rollout history:
```Console
$ kubectl set image deploy my-deploy nginx=nginx:1.19


$ kubectl rollout history deploy my-deploy

deployment.apps/my-deploy 
REVISION  CHANGE-CAUSE
1         <none>
3         version change to 20.0 to latest
4         version change to 20.0 to latest
```
The CHANGE-CAUSE annotation is copied to the deployment revisions upon creation. So, if you modify the CHANGE-CAUSE annotation on the deployment, the change will be reflected in the existing revisions as well. To set the right description in the annotation:

```Console
$ kubectl annotate deployment my-deploy kubernetes.io/change-cause="version change to 1.19"

$ kubectl rollout history deploy my-deploy
deployment.apps/my-deploy 
REVISION  CHANGE-CAUSE
1         <none>
3         version change to 20.0 to latest
4         version change to 1.19
```


### <a name="check the deployment  rollout"></a> edit a deployment
There are cases where is convenient change properties in the deployment:

```console
$ kubectl edit deploy my-deploy
```
The command open the editor and allow to change the properties:
```
....
replicas: 2
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: my-deploy
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: my-deploy
    spec:
      containers:
      - image: nginx:1.19
        imagePullPolicy: Always
        name: nginx
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
....
```

for example change the image version and save it.
whn you exist from command is diplay: "deployment.apps/my-deploy edited"


This is equivalent to first get the resource, edit it in text editor, and then apply the resource with the updated version:
```bash
$ kubectl get deploy my-deploy -o yaml > /tmp/nginx.yaml
vi /tmp/nginx.yaml
# do some edit, and then save the file

$ kubectl apply -f /tmp/nginx.yaml
deployment.apps/my-deploy configured

rm /tmp/nginx.yaml
```

**kubectl edit** allows you to do more significant changes more easily. 

### <a name="Create a pod yaml file"></a> Display labels associated with the pods

```console
$ kubectl get pod --show-labels
NAME                        READY   STATUS    RESTARTS   AGE     LABELS
my-deploy-f57f6fcc6-dpckv   1/1     Running   0          11m     app=my-deploy,pod-template-hash=f57f6fcc6
my-deploy-f57f6fcc6-lsvsm   1/1     Running   0          11m     app=my-deploy,pod-template-hash=f57f6fcc6
nginx                       1/1     Running   0          4h45m   run=nginx
```

### <a name="Create a pod yaml file"></a> Display the IP address of the pods

```Console
$ kubectl get pod -o wide
NAME                        READY   STATUS    RESTARTS   AGE     IP            NODE                                NOMINATED NODE   READINESS GATES
my-deploy-f57f6fcc6-dpckv   1/1     Running   0          13m     10.244.0.28   aks-nodepool1-18823728-vmss000000   <none>           <none>
my-deploy-f57f6fcc6-lsvsm   1/1     Running   0          13m     10.244.0.29   aks-nodepool1-18823728-vmss000000   <none>           <none>
nginx                       1/1     Running   0          4h48m   10.244.0.14   aks-nodepool1-18823728-vmss000000   <none>           <none>

```

### <a name="Create a pod yaml file"></a> Display the IP address of the nodes
```
$ kubectl get node -o wide
NAME                                STATUS   ROLES   AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
aks-nodepool1-18823728-vmss000000   Ready    agent   8h    v1.27.7   10.224.0.4    <none>        Ubuntu 22.04.3 LTS   5.15.0-1052-azure   containerd://1.7.5-1
```

### <a name="Create a pod yaml file"></a> Display the labels associated to the nodes

```
$ kubectl get node --show-labels
NAME                                STATUS   ROLES   AGE   VERSION   LABELS
aks-nodepool1-18823728-vmss000000   Ready    agent   8h    v1.27.7   agentpool=nodepool1,beta.kubernetes.io/arch=amd64,beta.kubernetes.io/instance-type=Standard_B2ms,beta.kubernetes.io/os=linux,failure-domain.beta.kubernetes.io/region=uksouth,failure-domain.beta.kubernetes.io/zone=0,kubernetes.azure.com/agentpool=nodepool1,kubernetes.azure.com/cluster=MC_k8s-1_aks1_uksouth,kubernetes.azure.com/consolidated-additional-properties=55a5b7c6-a950-11ee-805b-d61da3861a18,kubernetes.azure.com/kubelet-identity-client-id=70992d91-60ff-48ff-ab26-e73633e1ef1b,kubernetes.azure.com/mode=system,kubernetes.azure.com/node-image-version=AKSUbuntu-2204gen2containerd-202312.06.0,kubernetes.azure.com/nodepool-type=VirtualMachineScaleSets,kubernetes.azure.com/os-sku=Ubuntu,kubernetes.azure.com/role=agent,kubernetes.azure.com/storageprofile=managed,kubernetes.azure.com/storagetier=Premium_LRS,kubernetes.io/arch=amd64,kubernetes.io/hostname=aks-nodepool1-18823728-vmss000000,kubernetes.io/os=linux,kubernetes.io/role=agent,node-role.kubernetes.io/agent=,node.kubernetes.io/instance-type=Standard_B2ms,storageprofile=managed,storagetier=Premium_LRS,topology.disk.csi.azure.com/zone=,topology.kubernetes.io/region=uksouth,topology.kubernetes.io/zone=0
```

### <a name="Create a pod yaml file"></a> Create a service

```Console
$ kubectl run my-pod --image=nginx  # create  a new pod named my-pod
$ kubectl expose pod my-pod --name mypod-svc --port=80 

$ kubectl get svc
NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.0.0.1      <none>        443/TCP   8h
mypod-svc    ClusterIP   10.0.96.225   <none>        80/TCP    40s


$ kubectl get svc -o wide
NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE   SELECTOR
kubernetes   ClusterIP   10.0.0.1      <none>        443/TCP   8h    <none>
mypod-svc    ClusterIP   10.0.96.225   <none>        80/TCP    69s   run=my-pod
```
**kubectl get svc -o wide** allows to see the selector associated with the service.


### <a name="Create a pod yaml file"></a> discover the image used the pod
Two methods to get the information:

```console
$ kubectl describe pod my-pod | grep -i image

    Image:          nginx
    Image ID:       docker.io/library/nginx@sha256:2bdc49f2f8ae8d8dc50ed00f2ee56d00385c6f8bc8a8b320d0a294d9e3b49026
  Normal  Pulling    16m   kubelet            Pulling image "nginx"
  Normal  Pulled     16m   kubelet            Successfully pulled image "nginx" in 679.714582ms (679.722382ms including waiting)
```
if we want to see a couple of line after the subsequent two lines:

```console
$ kubectl describe pod my-pod | grep -i image -A 2

    Image:          nginx
    Image ID:       docker.io/library/nginx@sha256:2bdc49f2f8ae8d8dc50ed00f2ee56d00385c6f8bc8a8b320d0a294d9e3b49026
    Port:           <none>
    Host Port:      <none>
--
  Normal  Pulling    19m   kubelet            Pulling image "nginx"
  Normal  Pulled     19m   kubelet            Successfully pulled image "nginx" in 679.714582ms (679.722382ms including waiting)
  Normal  Created    19m   kubelet            Created container my-pod
  Normal  Started    19m   kubelet            Started container my-pod
```

```Console
$ kubectl get pod my-pod -o jsonpath='{.spec.containers[*].image}'; echo $'\n'
nginx
```

### <a name="Create a pod yaml file"></a> delete resources

Delete a pod in fast way:
```
$ kubectl delete pod my-pod --force
Warning: Immediate deletion does not wait for confirmation that the running resource has been terminated. The resource may continue to run on the cluster indefinitely.
pod "my-pod" force deleted
```
Without --force takes longer for timeout and graceful delete.


Delete a deployment:
```Console
$ kubectl delete deploy my-deploy

deployment.apps "my-deploy" deleted
```


Delete all the pods and deployments in specific namespace:
```
kubectl delete --all pods --namespace=foo
kubectl delete --all pods -namespace=foo
```

To delete all:
```
kubectl delete all --all --all-namespaces
```
The first `all` means the common resource kinds (pods, replicasets, deployments, ...) <br>
kubectl get all == kubectl get pods,rs,deployments, ... <br>
Note that `all` does not include:
- non namespaced resourced (e.g., clusterrolebindings, clusterroles, ...)
- configmaps
- rolebindings
- roles
- secrets

The second `--all` means to select all resources of the selected kinds.


### <a name="Create a pod yaml file"></a> kubectl explain 

**kubectl explain** gets documentation of various resources <br>

Example, let's see how we discover all the attributes:
```
kubectl explain pod.spec.containers
kubectl explain pod.spec.containers.readinessProbe
kubectl explain pod.spec.containers.readinessProbe.httpGet
```

````
kubectl explain pod.spec.containers | grep readiness -A 2 -B 2

readinessProbe        <Probe>
    Periodic probe of container service readiness. Container will be removed
    from service endpoints if the probe fails. Cannot be updated. More info:
    https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
```
we can dig in:
```Console
kubectl explain pod.spec.containers.readinessProbe | grep http -A 3
    https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
    Probe describes a health check to be performed against a container to
    determine whether it is alive or ready to receive traffic.
    
--
  httpGet       <HTTPGetAction>
    HTTPGet specifies the http request to perform.

  initialDelaySeconds   <integer>
    Number of seconds after the container has started before liveness probes are
--
    https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes

  periodSeconds <integer>
    How often (in seconds) to perform the probe. Default to 10 seconds. Minimum
--
    https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
```

```
kubectl explain pod.spec.containers.readinessProbe.httpGet
KIND:       Pod
VERSION:    v1

FIELD: httpGet <HTTPGetAction>

DESCRIPTION:
    HTTPGet specifies the http request to perform.
    HTTPGetAction describes an action based on HTTP Get requests.
    
FIELDS:
  host  <string>
    Host name to connect to, defaults to the pod IP. You probably want to set
    "Host" in httpHeaders instead.

  httpHeaders   <[]HTTPHeader>
    Custom headers to set in the request. HTTP allows repeated headers.

  path  <string>
    Path to access on the HTTP server.

  port  <IntOrString> -required-
    Name or number of the port to access on the container. Number must be in the
    range 1 to 65535. Name must be an IANA_SVC_NAME.

  scheme        <string>
    Scheme to use for connecting to the host. Defaults to HTTP.
    
    Possible enum values:
     - `"HTTP"` means that the scheme used will be http://
     - `"HTTPS"` means that the scheme used will be https://
```


### <a name="Reference"></a> Reference

https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands

`Tags: kubernetes` <br>
`date: 11-12-23`

