
<properties
pageTitle= 'Kubernetes: edit yaml with vim'
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

# Kubernetes: edit yaml with vim
When you create an object in Kubernetes, you must provide the object spec that describes its desired state. The information about objects are specified in yaml file known as a manifest. <br>
The yaml files are used with **kubectl** to create, modify, update the objects. <br>
Tools such as **kubectl** convert the information from a manifest file into JSON or another supported serialization format when making the API request over HTTP. <br>
In Linux the yaml manifest files are create and modify with **vim**. <br>
It is frequest cut and paste from Kubenetes documentation snippet of yaml (i.e. create a POD a deployment with request and limit, etc.). To be valid the yaml manifest files require the right indentation. <br>
Let's dscuss some tips to facilitate the creation/editing of yaml manifest files.


https://www.freecodecamp.org/news/vimrc-configuration-guide-customize-your-vim-editor/

### <a name=".vimrc file"></a>1. Configuring the .vimrc file
The **.vimrc** file control the vim behavior. Let's create an essential configuration adding some properties to the **.vimrc** file for editing yaml.

Create a **.vimrc** file in your home directory:
```bash
touch ~/.vimrc
```


Add the following lines to your **.vimrc** file:

```vim
set tabstop=2 softtabstop=2 shiftwidth=2
set expandtab
set number ruler
set autoindent smartindent
syntax enable
filetype plugin indent on
```

|                            |                                          |
| -------------------------- | ---------------------------------------- |
|`set tabstop=2`             | Set tab width to 2 columns.              |
|`softtabstop=2`             | The value of `softtabstop` equals how many columns (=spaces) the cursor moves right when you press `<Tab>`, and how many columns it moves left when you press `<BS>` (backspace) to erase a tab. |
|`shiftwidth=2`              | Set shift width to 2 spaces.             |
|`set expandtab`             | Use space characters instead of tabs. Prevent introduction of tab characters. In our case, replace the tab with two spaces |
|`set number ruler`          | A column of sequential line numbers will then display at the left side of the screen. |
|`set autoindent smartindent`| autoindent apply the indentation of the current line to the next, created by pressing enter in insert mode or with O or o in normal mode. <br> smartindent reacts to the syntax/style of the code you are editing |
|`syntax enable`             | turn on color syntax highlighting.       |
|`filetype plugin indent on` | it is like a combination of these commands: <br> `filetype on` <br> `filetype plugin on` <br> `filetype indent on` |

In vim to jump to a specific line use: row_number + G

### <a name="vim indenting with >"></a>2. vim - Indenting with > and n>
If you have an AKS cluster, you can create a basic yaml file for an NGINX Pod:
```bash
kubectl run mypod --image=nginx --dry-run=client -o yaml > mypod.yaml
```
You can use the **--dry-run=client** flag to preview the object that would be sent to your cluster, without really submitting it. This will give you a template for creating a deployment. <br>
The following manifest **mypod.yaml** is generated:
```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: mypod
  name: mypod
spec:
  containers:
  - image: nginx
    name: mypod
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```
Let's clean up the file:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: mypod
  name: mypod
spec:
  containers:
  - image: nginx
    name: mypod
```

The above file **mypod2.yaml** is quite similar to the basic yaml file in the [official doc](https://kubernetes.io/docs/concepts/workloads/pods/) to create an elemental pod with nginx image. <br>
We want to add a section to set a resource limit in the POD. Searching in the official doc we see a snippet related to requests and limits:

[![1]][1]

Paste the snippet in the file **mypod2.yaml**, a wrong indentation could be created:

[![2]][2]



In vim, press **SHIT+V** to enter in visual mode and then moving the arrow down to select all the text indentation needs to be changed:

[![3]][3]

When all the test is selected, press the key **"2"** + **">"** and all the text will shift on the right:

[![4]][4]

The yaml has now the right format.

- The sequence **n** + **">"** allows to indent the selected block shiting to the right.
- The sequence **n** + **"<"** allows to indent the selected block shiting to the left. <br>
**n** is the number of two space to apply the shift unit. <br>

### <a name="enhanced customization of vim"></a>3. vim - :retab and :set list

The file **mypod3-with-tab.yaml** contains a tab: 
```console
$ cat -T mypod3-with-tab.yaml 
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: mypod
  name: mypod
spec:
  containers:
  - image: nginx
    name: mypod
    resources:
      requests:
^I      memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```
This is visibile by presence of **^I**. <br> 
Open the file **mypod3-with-tab.yaml** by vim; to see the presence of wrong characters, use the command: **set list**

[![5]][5]

if we apply the manifest file we get an error:
```Console
$ kubectl apply -f mypod3-with-tab.yaml 
error: error parsing mypod3-with-tab.yaml: error converting YAML to JSON: yaml: line 13: found character that cannot start any token
```
The vim command **retab** allows to replace all the tab characters in the file with space:

[![6]][6]


### <a name="enhanced customization of vim"></a>3. multi-line values in yaml
There are cases where field in yaml file span over multiple lines. One example is a digital certificate.
To deal with multiple lines
The file **certificate-request.pem** contains a digital certificate.
The structure of **csr.yaml** is:
```
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: myuser
spec:
groups:
  - system:autheticated
  request: <Digital-Certificate-Here>
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
```
The digital cerficate can be insert in a single line `request: <Digital-Certificate-Here>` or insert in the request split up in multiple lines:

```Console
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: myuser
spec:
groups:
  - system:autheticated
  request: |
  XXXXXXXXXXXXX
  XXXXXXXXXXXXX
  XXXXXXXXXXXXX
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
```



To append the certificate to the yaml file **csr.yaml**:
```bash
cat certificate-request.pem | base64 >> csr1.yaml
```

Open by vim the file csr1.yaml:

[![7]][7]

In vim, position the cursor at beginning of certificate abd press **SHIT+V** to enter in visual mode. Moving the arrow down to select all the digital certificate:

[![8]][8]
push the key **d**.




<br>

Move the cursor under the section **request: |** and push **p** to paste the buffer:
[![9]][9]

Press **SHIT+V** to enter in visual mode and select all the digital certificate rows:

[![10]][10]

Push the key **>** to shift the selected block to the right:

[![11]][11]

We have now the righ format.

### <a name="enhanced customization of vim"></a>4. Annex: enhanced customization of vim
For enhanced customization of vim add the **~/.vimrc** file the following statements:
```vim
" Disable compatibility with vi which can cause unexpected issues.
set nocompatible

" Enable type file detection. Vim will be able to try to detect the type of file in use.
filetype on

" Enable plugins and load plugin for the detected file type.
filetype plugin on

" Load an indent file for the detected file type.
filetype indent on

" Turn syntax highlighting on.
syntax on

" Display numbers to each line on the left-hand side.
set number
```

You can pinpoint exactly where the cursor is located by highlighting the line it is on horizontally and vertically.
```vim
" Highlight cursor line underneath the cursor horizontally.
set cursorline

" Highlight cursor line underneath the cursor vertically.
set cursorcolumn
```

Common settings:
```vim
" Set shift width to 4 spaces.
set shiftwidth=4

" Set tab width to 4 columns.
set tabstop=4

" Use space characters instead of tabs.
set expandtab

" Do not save backup files.
set nobackup

" Do not let cursor scroll below or above N number of lines when scrolling.
set scrolloff=10

" Do not wrap lines. Allow long lines to extend as far as the line goes.
set nowrap

" While searching though a file incrementally highlight matching characters as you type.
set incsearch

" Ignore capital letters during search.
set ignorecase

" Override the ignorecase option if searching for capital letters.
" This will allow you to search specifically for capital letters.
set smartcase

" Show partial command you type in the last line of the screen.
set showcmd

" Show the mode you are on the last line.
set showmode

" Show matching words during a search.
set showmatch

" Use highlighting when doing a search.
set hlsearch

" Set the commands to save in history default number is 20.
set history=1000
```

### <a name="reference"></a>5. Reference

https://kube.academy/courses/how-to-prepare-for-the-cka-exam/lessons/editing-yaml-with-vim

`Tags: AKS` <br>
`date: 29-12-23`


<!--Image References-->

[1]: ./media/doc1-kubernetes.png "Kubernetes documentation: resource limit"
[2]: ./media/02.png "wrong yaml indentation in resource limit section"
[3]: ./media/03.png "wrong yaml indentation in resource limit section"
[4]: ./media/04.png "wrong yaml indentation in resource limit section"
[5]: ./media/05.png "vim: set list command"
[6]: ./media/06.png "vim: retab command"
[7]: ./media/07.png "open up the file with vim with digital certificate appended at the end"
[8]: ./media/08.png
[9]: ./media/09.png
[10]: ./media/10.png
[11]: ./media/11.png

<!--Link References-->
